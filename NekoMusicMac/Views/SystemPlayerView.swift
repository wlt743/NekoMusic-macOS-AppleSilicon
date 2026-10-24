import AVKit
import SwiftUI

/// 直接使用系统的 AVPlayerView 控件（原生播放界面，含进度、播放、音量、全屏）
struct SystemPlayerView: NSViewRepresentable {
    let player: AVPlayer?
    var controlsStyle: AVPlayerViewControlsStyle = .inline
    var showsSharingButton = false

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = controlsStyle
        view.showsSharingServiceButton = showsSharingButton
        view.showsFullScreenToggleButton = false
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
        if view.player !== player {
            view.player = player
        }
        view.controlsStyle = controlsStyle
        view.showsSharingServiceButton = showsSharingButton
    }
}
