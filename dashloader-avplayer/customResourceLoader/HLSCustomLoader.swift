//
//  HLSCustomLoader.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/10.
//

import Foundation

// handsOn 컨셉에 맞도록 기능별로 HLSCustomLoader를 나누었습니다.
// 적용시에는 여러 기능을 섞어 사용합니다.

// 화질을 제한하는 CustomResourceLoader 입니다.
class HLSRestrictResolutionCustomLoader: NSObject, CustomLoader {

    func loadResource(url: URL,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        Call.get(url: url.recoveryScheme) {
            let result = $0.flatMap({ $0.toString })
                .map { $0.restrictResoultion() }
                .flatMap({ $0.toData })

            completion(result)
        }
    }
}

// 영상의 일정부분만 잘라 재생하는 CustomResourceLoader 입니다.
// ex. 미리보기 또는 편집
class HLSSliceCustomLoader: NSObject, CustomLoader {

    func loadResource(url: URL,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        Call.get(url: url.recoveryScheme) {
            let result = $0.flatMap({ $0.toString })
                .map { $0.sliceMedia(duration: 10.0) }
                .flatMap({ $0.toData })

            completion(result)
        }
    }
}

// 일정부분을 자른 서로다른 영상을 합성해 재생하는 CustomResourceLoader 입니다.
class HLSMegeSliceCustomLoader: NSObject, CustomLoader {

    func loadResource(url: URL,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        Call.get(url: url.recoveryScheme) {
            let result = $0.flatMap({ $0.toString })
                .map { $0.sliceWithMergeMedia(duration: 10) }
                .flatMap({ $0.toData })

            completion(result)
        }
    }
}

// MARK: - Functions
private extension String {
    // 화질 제한
    func restrictResoultion() -> String {
        guard isMasterPlaylist else { return self }

        let resolutions = 480...1080
        return components(separatedBy: M3UTags.stream.rawValue)
            .compactMap ({
                if let resolution = $0.resolutionValue {
                    if resolutions.contains(resolution) {
                        return $0
                    } else {
                        return nil
                    }
                } else {
                    return $0
                }
            })
            .joined(separator: M3UTags.stream.rawValue)
    }

    // 미디어 길이 제한
    func sliceMedia(duration: TimeInterval) -> String {
        guard isMediaPlaylist else { return self }

        var max = duration
        var mediaPlaylist = components(separatedBy: M3UTags.mediaDuration.rawValue)
            .compactMap({
                if $0.contains(M3UTags.initM3U.rawValue) {
                    return $0
                } else if let mediaDuration = $0.firstDoubleValue,
                          max - mediaDuration > .zero {
                    max -= mediaDuration
                    return $0
                } else {
                    return nil
                }
            })
            .joined(separator: M3UTags.mediaDuration.rawValue)

        if !mediaPlaylist.contains(M3UTags.mediaEnd.rawValue) {
            mediaPlaylist.append("\n\(M3UTags.mediaEnd.rawValue)")
        }

        return mediaPlaylist
    }

    // 미디어 길이 제한 및 머지
    //
    // 서로다른 미디어를 섞어도 관계없으나 이곳에선 동일한 컨텐츠를 합성
    func sliceWithMergeMedia(duration: TimeInterval) -> String {
        guard isMediaPlaylist else { return self }

        var max = duration
        let haeder = components(separatedBy: M3UTags.mediaDuration.rawValue)
            .first(where: { $0.contains(M3UTags.initM3U.rawValue) }) ?? ""
        let mediaPlaylist = components(separatedBy: M3UTags.mediaDuration.rawValue)
            .compactMap({
                if $0.contains(M3UTags.initM3U.rawValue) {
                    return ""
                } else if let mediaDuration = $0.firstDoubleValue,
                          max - mediaDuration > .zero {
                    max -= mediaDuration
                    return $0
                } else {
                    return nil
                }
            })
            .joined(separator: M3UTags.mediaDuration.rawValue)
            .components(separatedBy: "\n")
            .filter { !$0.contains(M3UTags.mediaEnd.rawValue) }
            .joined(separator: "\n")

        return [haeder,
                mediaPlaylist,
                M3UTags.discontinuity.rawValue,
                mediaPlaylist,
                M3UTags.mediaEnd.rawValue].joined(separator: "\n")
    }
}

// MARK: - Utils
private extension String {

    enum M3UTags: String {
        case initM3U = "#EXTM3U"
        case stream = "#EXT-X-STREAM-INF"
        case iFrameStream = "EXT-X-I-FRAME-STREAM-INF"
        case mediaDuration = "#EXTINF:"
        case mediaEnd = "#EXT-X-ENDLIST"
        case discontinuity = "#EXT-X-DISCONTINUITY"
    }

    // MasterPlaylist 여부
    var isMasterPlaylist: Bool {
        contains(M3UTags.stream.rawValue)
    }

    // MediaPlaylist 여부
    var isMediaPlaylist: Bool {
        contains(M3UTags.mediaDuration.rawValue)
    }

    // 문자열에서 해상도 찾기
    var resolutionValue: Int? {
        guard let resolutionValue = components(separatedBy: "RESOLUTION")
                .last?
                .components(separatedBy: ",")
                .first?
                .components(separatedBy: "x")
                .compactMap({ Int($0) })
                .min()
        else { return nil }

        return Int(resolutionValue)
    }

    var firstDoubleValue: Double? {
        components(separatedBy: ",")
            .compactMap({ Double($0) })
            .first
    }
}
