//
//  PlayView.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import AVFoundation
import UIKit

class PlayView: UIView {

    var playerLayer: AVPlayerLayer {
        guard let layer = layer as? AVPlayerLayer else { return AVPlayerLayer() }
        return layer
    }

    // Override UIView property
    override public static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
}
