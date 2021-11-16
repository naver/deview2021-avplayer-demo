//
//  DashToHLSLoader.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import Foundation

class DashToHLSLoader: NSObject, CustomLoader {

    var mpd: MPD?

    var handleMPDCompletion: ((Result<Data, Error>) -> Void)?

    func loadResource(url: URL,
                      completion: @escaping (Result<Data, Error>) -> Void) {

        if url.absoluteString.contains("mpd") {
            // MPD 요청시
            // MPD를 획득 후 MasterPlaylist를 만들어 전달합니다.
            Call.get(url: url.recoveryScheme.recoverMPDIfIsTempM3U8) { [weak self] in
                switch $0 {
                case .failure(let error):
                    error.printDescription()
                    completion(.failure(error))

                case .success(let data):
                    self?.parseXML(data: data, completion: completion)
                }
            }
        } else if url.lastPathComponent.contains("m3u8") {
            // M3U8 요청시
            // MPD 정보를 활용해 만든 가상의 미디어 플레이 리스트 요청입니다.
            // MPD 정보를 이용해 MediaPlaylist를 생성해 전달합니다.
            makeMediaM3U8(url: url, completion: completion)
        } else {
            // 이 구간으로 들어오는 요청이 있다면 잘 못 된 요청을 의미합니다.
            // MPD, MediaPlaylist M3U8만 커스텀로드하며
            // 이외 요청에 대해서는 위임되지 않도록 사전에 Scheme를 원복시켜 주어야 합니다.
            print("loadResource: wrong url", url.absoluteString)
        }
    }

    func parseXML(data: Data,
                  completion: @escaping(Result<Data, Error>) -> Void) {
        self.handleMPDCompletion = completion
        let xml = XMLParser(data: data)
        xml.delegate = self
        xml.parse()
    }

    func makeMasterM3U8() {
        guard let mpd = self.mpd else {
            handleMPDCompletion?(.failure(SampleError.failedToCreateM3U))
            return
        }

        var lines: [String] = ["#EXTM3U"]
        lines.append(contentsOf: mpd.hlsAttributes)

        if let data = lines
            .joined(separator: "\n")
            .data(using: .utf8) {
            handleMPDCompletion?(.success(data))
        } else {
            handleMPDCompletion?(.failure(SampleError.failedToCreateM3U))
        }
    }

    func makeMediaM3U8(url: URL,
                       completion: @escaping(Result<Data, Error>) -> Void) {
        guard let mpd = self.mpd,
            let id = url.lastPathComponent.components(separatedBy: ".").first,
              let segmenttemplate = mpd.period.adaptationset.first(where: {
                    $0.representation.first(where: { $0.id == id }) != nil
              })?.segmenttemplate else { return }

        var lines: [String] = ["#EXTM3U"]
        let mediaDuration = mpd.mediaPresentationDuration
        let targetDuration = (TimeInterval(segmenttemplate.duration) ?? .zero)/(TimeInterval(segmenttemplate.timescale) ?? 1)
        let quotient = Int(mediaDuration / targetDuration)
        let remainder = mediaDuration.truncatingRemainder(dividingBy: targetDuration)

        lines.append(contentsOf: [
            "#EXT-X-TARGETDURATION:\(targetDuration)",
            "#EXT-X-VERSION:3",
            "#EXT-X-MEDIA-SEQUENCE:0",
            "#EXT-X-PLAYLIST-TYPE:VOD"
        ])

        var basePath = url.deletingLastPathComponent()
            .recoveryScheme
            .absoluteString
        basePath += segmenttemplate.media.replacingOccurrences(of: "$RepresentationID$", with: id)
        for index in 0..<quotient {
            lines.append("#EXTINF:\(targetDuration),")
            lines.append(basePath.replacingOccurrences(of: "$Number$", with: "\(index)"))
        }

        lines.append("#EXTINF:\(remainder),")
        lines.append(basePath.replacingOccurrences(of: "$Number$", with: "\(quotient)"))
        lines.append("#EXT-X-ENDLIST")

        if let data = lines.joined(separator: "\n").data(using: .utf8) {
            completion(.success(data))
        } else {
            completion(.failure(SampleError.failedToCreateM3U))
        }
    }
}

extension DashToHLSLoader: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        switch elementName.lowercased() {
        case "mpd":
            if let mpd = MPD(attributeDict: attributeDict) {
                self.mpd = mpd
            }
        case "adaptationset":
            if let adaptationset = Adaptationset(attributeDict: attributeDict) {
                mpd?.period.adaptationset.append(adaptationset)
            }
        case "representation":
            if let representation = Representation(attributeDict: attributeDict) {
                mpd?.period.adaptationset.last?.representation.append(representation)
            }
        case "segmenttemplate":
            if let segmenttemplate = Segmenttemplate(attributeDict: attributeDict) {
                mpd?.period.adaptationset.last?.segmenttemplate = segmenttemplate
            }
        default: break
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        makeMasterM3U8()
    }
}
