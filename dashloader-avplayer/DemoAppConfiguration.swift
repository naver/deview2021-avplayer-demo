//
//  DemoAppConfiguration.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/25.
//

import Foundation

struct DemoAppConfiguration {
    enum Path: String {
        case hls = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
        case dash = "https://dash.akamaized.net/akamai/bbb_30fps/bbb_30fps.mpd"

        var toURL: URL? {
            URL(string: rawValue)
        }
    }

    enum ObserveKey {
        case status
    }
}
