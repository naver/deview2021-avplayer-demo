//
//  MPD.swift
//  dashloader-avplayer
//
//  Created by USER on 2021/09/25.
//

import Foundation

class MPD {
    var baseURL: String?
    var period: Period
    var mediaPresentationDuration: TimeInterval

    init?(attributeDict: [String: String]) {
        guard let duration = attributeDict["mediaPresentationDuration"],
              let mediaPresentationDuration = duration.toMPDDuration else { return nil }
        self.baseURL = nil
        self.period = Period()
        self.mediaPresentationDuration = mediaPresentationDuration
    }

    var hlsAttributes: [String] {
        period.adaptationset
            .flatMap {
                $0.representation
                    // 너무 큰 화질 제거 Bandwidth: 14_931_538 < 14_000_000
                    .filter { Int($0.bandwidth) ?? .zero < 14_000_000 }
                    .map { $0.hlsAttribute }
            }
    }
}

class Period {
    var adaptationset: [Adaptationset] = []
}

class Adaptationset {
    let mimeType: String
    let contentType: String
    let subsegmentAlignment: String
    let subsegmentStartsWithSAP: String
    var segmenttemplate: Segmenttemplate?
    var representation: [Representation]

    init?(attributeDict: [String: String]) {
        guard let mimeType = attributeDict["mimeType"],
              let contentType = attributeDict["contentType"],
              let subsegmentAlignment = attributeDict["subsegmentAlignment"],
              let subsegmentStartsWithSAP = attributeDict["subsegmentStartsWithSAP"] else { return nil }

        self.mimeType = mimeType
        self.contentType = contentType
        self.subsegmentAlignment = subsegmentAlignment
        self.subsegmentStartsWithSAP = subsegmentStartsWithSAP
        self.representation = []
    }
}

class Segmenttemplate {
    let duration: String
    let timescale: String
    let media: String
    let startNumber: String
    let initialization: String

    init?(attributeDict: [String: String]) {
        guard let duration = attributeDict["duration"],
              let timescale = attributeDict["timescale"],
              let media = attributeDict["media"],
              let startNumber = attributeDict["startNumber"],
              let initialization = attributeDict["initialization"] else { return nil }

        self.duration = duration
        self.timescale = timescale
        self.media = media
        self.startNumber = startNumber
        self.initialization = initialization
    }

    var fileExtensions: String? {
        initialization.components(separatedBy: ".").last
    }
}

class Representation {
    let id: String
    let codecs: String
    let bandwidth: String
    let width: String
    let height: String
    let frameRate: String
    let sar: String
    let scanType: String

    init?(attributeDict: [String: String]) {
        guard let id = attributeDict["id"],
              let codecs = attributeDict["codecs"],
              let bandwidth = attributeDict["bandwidth"],
              let width = attributeDict["width"],
              let height = attributeDict["height"],
              let frameRate = attributeDict["frameRate"],
              let sar = attributeDict["sar"],
              let scanType = attributeDict["scanType"] else { return nil }

        self.id = id
        self.codecs = codecs
        self.bandwidth = bandwidth
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.sar = sar
        self.scanType = scanType
    }

    var hlsAttribute: String {
        return "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=\(bandwidth),CODECS=\"\(codecs)\"\n\(id).m3u8\n"
    }
}

private extension String {
    var toMPDDuration: TimeInterval? {
        guard var timeValue = self.components(separatedBy: "PT").last,
              !timeValue.isEmpty else { return nil }

        var duration: TimeInterval = .zero
        if timeValue.contains("H"),
           let value = timeValue.components(separatedBy: "H").first,
           let integer = Int(value) {
            duration += TimeInterval(integer * 3600)
            timeValue = timeValue.components(separatedBy: "H").last ?? ""
        }

        if timeValue.contains("M"),
           let value = timeValue.components(separatedBy: "M").first,
           let integer = Int(value) {
            duration += TimeInterval(integer * 60)
            timeValue = timeValue.components(separatedBy: "M").last ?? ""
        }

        if timeValue.contains("S"),
           let value = timeValue.components(separatedBy: "S").first,
           let time = TimeInterval(value) {
            duration += time
        }

        return duration
    }
}
