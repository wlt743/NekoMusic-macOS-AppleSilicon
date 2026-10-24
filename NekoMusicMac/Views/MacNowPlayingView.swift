import SwiftUI

/// macOS 播放页：封面模糊背景 + 左封面右歌词
struct MacNowPlayingView: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var coverImage: NSImage?

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()
                .allowsHitTesting(false)
            content
                .zIndex(1)
        }
        .onAppear { loadCover() }
        .onChange(of: playerService.currentMusic?.id) { _ in loadCover() }
    }

    // MARK: - 背景（封面模糊）

    private var backdrop: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                if let coverImage {
                    Image(nsImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .blur(radius: 90)
                        .saturation(1.35)
                        .opacity(0.75)
                }
                RadialGradient(
                    colors: [.black.opacity(0.18), .black.opacity(0.72)],
                    center: .center,
                    startRadius: 80,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.75
                )
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header

            GeometryReader { geo in
                // 左信息栏固定占窗口宽度的 34%，其余给歌词
                let leftWidth = geo.size.width * 0.326
                let gap = geo.size.width * 0.03
                // 封面取左栏宽度与可用高度的较小值，保证不溢出
                let coverSide = min(leftWidth, geo.size.height * 0.63)

                HStack(alignment: .top, spacing: gap) {
                    leftPanel(side: coverSide)
                        .frame(width: leftWidth)
                        .padding(.top, 44)

                    lyricsPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.leading, geo.size.width * 0.09)
                .padding(.trailing, geo.size.width * 0.04)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack {
            Spacer()

            Button {
                dismissWindow(id: "now-playing")
            } label: {
                Label("收起", systemImage: "chevron.down")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.16), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("收起播放页（Esc）")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func leftPanel(side: CGFloat) -> some View {
        VStack(spacing: 26) {
            MacCover(musicId: playerService.currentMusic?.id ?? 0, size: side)
                .frame(width: side, height: side)
                .shadow(color: .black.opacity(0.45), radius: 30, y: 14)

            VStack(spacing: 5) {
                Text(playerService.currentMusic?.title ?? "未在播放")
                    .font(.system(size: 26, weight: .semibold))
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                Text(playerService.currentMusic?.artist ?? "")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }

            VStack(spacing: 2) {
                NativeSlider(
                    value: Binding(
                        get: { min(playerService.currentPosition, max(playerService.duration, 0.1)) },
                        set: { playerService.seekTo(position: $0) }
                    ),
                    range: 0...max(playerService.duration, 0.1),
                    controlSize: .small,
                    accessibilityLabel: "播放进度"
                )
                HStack {
                    Text(Self.format(playerService.currentPosition))
                        .font(.caption2).monospacedDigit()
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                    Text(Self.format(playerService.duration))
                        .font(.caption2).monospacedDigit()
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            HStack(spacing: 0) {
                controlButton { playerService.togglePlayMode() } icon: {
                    Image(systemName: playerService.playMode.icon).font(.system(size: 22))
                }
                controlButton { playerService.previous() } icon: {
                    Image(systemName: "backward.fill").font(.system(size: 26))
                }
                controlButton { playerService.togglePlayPause() } icon: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 44))
                        .frame(height: 50)
                }
                controlButton { playerService.next() } icon: {
                    Image(systemName: "forward.fill").font(.system(size: 26))
                }
                controlButton { playerService.toggleFavorite() } icon: {
                    Image(systemName: playerService.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(playerService.isFavorite ? Color.accentColor : .white.opacity(0.85))
                }
            }
            .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var lyricsPanel: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .center, spacing: 32) {
                        if playerService.lyricLines.isEmpty {
                            Text("播放歌曲并在此处查看歌词。")
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            ForEach(Array(playerService.lyricLines.enumerated()), id: \.offset) { index, line in
                                lyricRow(index: index, text: line.text, time: line.time)
                                    .id(index)
                            }
                        }
                    }
                    // 上下留白，让首尾行也能滚到正中
                    .padding(.vertical, geo.size.height * 0.42)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.never)
                .onAppear { center(on: 0, proxy: proxy) }
                .onChange(of: playerService.currentLyricIndex) { index in
                    // 前奏期间（index == -1）强制把第一句滚到中间
                    center(on: max(index, 0), proxy: proxy)
                }
            }
        }
    }

    /// 把指定歌词行滚到视图正中
    private func center(on index: Int, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(index, anchor: .center)
        }
    }

    private func lyricRow(index: Int, text: String, time: TimeInterval) -> some View {
        let isCurrent = index == playerService.currentLyricIndex
        return Button {
            playerService.seekTo(position: time)
        } label: {
            Text(text)
                .font(.system(
                    size: isCurrent ? 38 : 25,
                    weight: isCurrent ? .bold : .regular
                ))
                .foregroundStyle(isCurrent ? .white : .white.opacity(0.36))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.22), value: isCurrent)
        }
        .buttonStyle(.plain)
    }

    private func controlButton<Icon: View>(
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            icon()
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    private func loadCover() {
        guard let musicID = playerService.currentMusic?.id, musicID > 0 else {
            coverImage = nil
            return
        }
        let urlString = APIConfig.buildMusicCoverURL(musicId: musicID, coverFilePath: nil)
        Task {
            if let meta = await ID3MetadataReader.load(urlString: playerService.currentAudioURL?.absoluteString ?? ""),
               let data = meta.cover, let img = NSImage(data: data) {
                await MainActor.run { self.coverImage = img }
                return
            }
            guard let url = URL(string: urlString) else { return }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = NSImage(data: data) {
                await MainActor.run { self.coverImage = img }
            }
        }
    }

    private static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
