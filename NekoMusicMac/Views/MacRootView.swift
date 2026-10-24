import SwiftUI

/// macOS 主界面：侧边栏 + 内容区 + 底部浮动播放条
struct MacRootView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var appearance: AppearanceSettings

    @State private var selection: SidebarItem? = .home
    @State private var showNowPlaying = false
    @State private var isFullScreen = false
    @Environment(\.openWindow) private var openWindow

    enum SidebarItem: Hashable {
        case home, ranking, latest, profile
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
        } detail: {
            NavigationStack {
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background { MacWallpaperBackdrop() }
            }
            .id(selection)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if playerService.currentMusic != nil {
                MacMiniPlayerBar(showNowPlaying: $showNowPlaying)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }
        }
        .toolbar(showNowPlaying && isFullScreen ? .hidden : .automatic, for: .windowToolbar)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullScreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullScreen = false
        }
        .onAppear {
            isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNowPlaying)) { _ in
            openWindow(id: "now-playing")
        }
        .animation(.easeInOut(duration: 0.22), value: showNowPlaying)
        .onChange(of: playerService.presentNowPlaying) { value in
            // 桌面端不自动全屏播放页：点歌即播，底部条出现，需要时再点开
            guard value else { return }
            playerService.presentNowPlaying = false
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                Label("主页", systemImage: "house").tag(SidebarItem.home)
                Label("排行榜", systemImage: "chart.bar").tag(SidebarItem.ranking)
                Label("最新上架", systemImage: "sparkles").tag(SidebarItem.latest)
            }
            Section {
                Label("我的", systemImage: "person.crop.circle").tag(SidebarItem.profile)
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .home {
        case .home:
            MacHomeView()
        case .ranking:
            MacMusicListView(title: "排行榜", mode: .ranking)
        case .latest:
            MacMusicListView(title: "最新上架", mode: .latest)
        case .profile:
            MacProfileView()
        }
    }
}


extension Notification.Name {
    static let openNowPlaying = Notification.Name("NekoMusicMac.openNowPlaying")
}


/// 让窗口标题栏透明：红绿灯浮在内容之上，内容可以铺满
struct WindowTitlebarConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
