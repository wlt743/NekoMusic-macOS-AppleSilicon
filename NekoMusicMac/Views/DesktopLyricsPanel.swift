import AppKit
import SwiftUI

/// 桌面歌词悬浮窗控制器
@MainActor
final class DesktopLyricsController {
    static let shared = DesktopLyricsController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    private init() {}

    var isVisible: Bool { panel?.isVisible ?? false }

    func show(player: AudioPlayerService, appearance: AppearanceSettings) {
        if panel == nil {
            let root = DesktopLyricsView()
                .environmentObject(player)
                .environmentObject(appearance)
            let hosting = NSHostingView(rootView: AnyView(root))
            hosting.frame = NSRect(x: 0, y: 0, width: 620, height: 92)

            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 92),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hosting
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false

            // 默认放在屏幕下方居中
            if let screen = NSScreen.main {
                let frame = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(x: frame.midX - 310, y: frame.minY + 90))
            }

            self.panel = panel
            self.hostingView = hosting
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle(player: AudioPlayerService, appearance: AppearanceSettings) {
        if isVisible {
            hide()
        } else {
            show(player: player, appearance: appearance)
        }
    }
}

/// 桌面歌词内容
struct DesktopLyricsView: View {
    @EnvironmentObject var player: AudioPlayerService
    @EnvironmentObject var appearance: AppearanceSettings

    var body: some View {
        Text(player.currentLyricText ?? "♪ NekoMusic")
            .font(.system(size: appearance.lyricFontSize, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.65), radius: 3, y: 1)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.black.opacity(0.28))
            }
    }
}
