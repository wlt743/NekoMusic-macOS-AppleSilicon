import SwiftUI

@main
struct NekoMusicMacApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var playerService = AudioPlayerService.shared
    @StateObject private var appearance = AppearanceSettings.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environmentObject(authService)
                .environmentObject(playerService)
                .environmentObject(appearance)
                .tint(appearance.tintColor)
                .frame(minWidth: 940, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 740)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(after: .newItem) {
                Button("播放 / 暂停") {
                    AudioPlayerService.shared.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("打开迷你播放器") {
                    openWindow(id: "mini-player")
                }
                .keyboardShortcut("m", modifiers: [.command, .option])

                Button("正在播放") {
                    NotificationCenter.default.post(name: .openNowPlaying, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }

        // 播放页：独立窗口
        Window("正在播放", id: "now-playing") {
            MacNowPlayingView()
                .environmentObject(playerService)
                .environmentObject(appearance)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        .restorationBehavior(.disabled)

        // 迷你播放器：独立窗口，左封面右歌词
        Window("迷你播放器", id: "mini-player") {
            MiniPlayerWindow()
                .environmentObject(playerService)
                .environmentObject(appearance)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 640, height: 380)
        .restorationBehavior(.disabled)
    }
}
