//
//  ViewController.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var playView: PlayView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!

    private var observations: [DemoAppConfiguration.ObserveKey: NSKeyValueObservation] = [:]
    let player = AVPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()

        playView.playerLayer.player = player
    }

    var delegate: CustomAssetDelegate?

    // 1. HLS 화질제한 재생
    @IBAction func button1Tapped(_ sender: Any) {
        if player.rate != .zero { stop() }

        guard let hlsURL = DemoAppConfiguration.Path.hls.toURL else { return }

        // 1. scheme 변경 -> custom scheme
        let url = hlsURL
            .change(scheme: "chls")
        let urlAsset = AVURLAsset(url: url)

        // 2. CustomAssetDelegate(AVAssetResourceLoaderDelegate 설정)
        let customAssetDelegate = CustomAssetDelegate(loader: HLSRestrictResolutionCustomLoader())
        self.delegate = customAssetDelegate
        urlAsset.resourceLoader.setDelegate(customAssetDelegate,
                                            queue: DispatchQueue.global(qos: .utility))
        urlAsset.loadValuesAsynchronously(forKeys: ["playable", "duration"]) { [weak self] in
            self?.play(playItem: AVPlayerItem(asset: urlAsset))
        }
    }

    // 2. HLS Media 길이제한
    @IBAction func button2Tapped(_ sender: Any) {
        if player.rate != .zero { stop() }

        guard let hlsURL = DemoAppConfiguration.Path.hls.toURL else { return }

        // 1. scheme 변경 -> custom scheme
        let url = hlsURL
            .change(scheme: "chls")
        let urlAsset = AVURLAsset(url: url)

        // 2. CustomAssetDelegate(AVAssetResourceLoaderDelegate 설정)
        let customAssetDelegate = CustomAssetDelegate(loader: HLSSliceCustomLoader())
        self.delegate = customAssetDelegate
        urlAsset.resourceLoader.setDelegate(customAssetDelegate,
                                            queue: DispatchQueue.global(qos: .utility))
        urlAsset.loadValuesAsynchronously(forKeys: ["playable", "duration"]) { [weak self] in
            self?.play(playItem: AVPlayerItem(asset: urlAsset))
        }
    }

    // 3. HLS Media 길이제한 & 미디어 합성
    @IBAction func button3Tapped(_ sender: Any) {
        if player.rate != .zero { stop() }

        guard let hlsURL = DemoAppConfiguration.Path.hls.toURL else { return }

        // 1. scheme 변경 -> custom scheme
        let url = hlsURL
            .change(scheme: "chls")
        let urlAsset = AVURLAsset(url: url)

        // 2. CustomAssetDelegate(AVAssetResourceLoaderDelegate 설정)
        let customAssetDelegate = CustomAssetDelegate(loader: HLSMegeSliceCustomLoader())
        self.delegate = customAssetDelegate
        urlAsset.resourceLoader.setDelegate(customAssetDelegate,
                                            queue: DispatchQueue.global(qos: .utility))
        urlAsset.loadValuesAsynchronously(forKeys: ["playable", "duration"]) { [weak self] in
            self?.play(playItem: AVPlayerItem(asset: urlAsset))
        }
    }

    // 4. DASH 재생하기
    @IBAction func button4Tapped(_ sender: Any) {
        if player.rate != .zero { stop() }

        guard let dashURL = DemoAppConfiguration.Path.dash.toURL else { return }

        // 1. scheme 변경 -> custom scheme
        let url = dashURL
            .change(scheme: "cdash")
            .tempM3U8
        let urlAsset = AVURLAsset(url: url)

        // 2. CustomAssetDelegate(AVAssetResourceLoaderDelegate 설정)
        let customAssetDelegate = CustomAssetDelegate(loader: DashToHLSLoader())
        self.delegate = customAssetDelegate
        urlAsset.resourceLoader.setDelegate(customAssetDelegate,
                                            queue: DispatchQueue.global(qos: .utility))
        urlAsset.loadValuesAsynchronously(forKeys: ["playable", "duration"]) { [weak self] in
            self?.play(playItem: AVPlayerItem(asset: urlAsset))
        }
    }

    private func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)

        observations.forEach { $0.value.invalidate() }
        observations = [:]
    }

    private func play(playItem: AVPlayerItem) {
        observations[.status] = playItem.observe(\.status) { playerItem, _ in
            if let error = playerItem.error {
                error.printDescription()
            } else {
                print("update AVPlayerItem.status: \(playerItem.status.rawString)")
            }
        }
        player.replaceCurrentItem(with: playItem)
        player.play()
    }
}

private extension AVPlayerItem.Status {

    var rawString: String {
        switch self {
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        case .unknown: fallthrough
        @unknown default:
            return "unknown"
        }
    }
}
