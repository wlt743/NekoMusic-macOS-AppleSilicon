import SwiftUI
import AVKit

/// 独立迷你播放器窗口：参考 Apple Music 布局（左封面 + 右歌词）
struct MiniPlayerWindow: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @Environment(\.dismiss) private var dismiss

    @State private var volume: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 16)
                .padding(.top, 12)

            GeometryReader { geo in
                // 左栏占窗口宽度 32%，间距 4%，其余给歌词
                let leftWidth = geo.size.width * 0.32
                HStack(alignment: .top, spacing: geo.size.width * 0.04) {
                    leftColumn
                        .frame(width: leftWidth)

                    lyricsPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .padding(.horizontal, geo.size.width * 0.05)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 640, minHeight: 380)
        .background { backdrop }
        .onAppear { volume = Double(playerService.volume) }
    }

    // MARK: - 顶部工具栏

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                NSApp.keyWindow?.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                NSApp.hide(nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("显示主窗口")

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                NativeSlider(
                    value: $volume,
                    range: 0...1,
                    controlSize: .mini,
                    accessibilityLabel: "音量",
                    onEditingChanged: { _ in playerService.setVolume(volume) }
                )
                .frame(width: 110, height: 16)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 左侧

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            MacCover(musicId: playerService.currentMusic?.id ?? 0, size: 220)
                .shadow(color: .black.opacity(0.28), radius: 14, y: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(playerService.currentMusic?.title ?? "未在播放")
                    .font(.headline)
                    .lineLimit(1)
                Text(playerService.currentMusic?.artist ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // 系统原生播放控件（进度 / 播放 / 音量 / 全屏）
            VStack(spacing: 4) {
                NativeSlider(
                    value: Binding(
                        get: { min(playerService.currentPosition, max(playerService.duration, 0.1)) },
                        set: { playerService.seekTo(position: $0) }
                    ),
                    range: 0...max(playerService.duration, 0.1),
                    controlSize: .small,
                    accessibilityLabel: "播放进度"
                )
                .frame(height: 18)

                HStack {
                    Text(Self.format(playerService.currentPosition))
                        .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.format(playerService.duration))
                        .font(.caption2).monospacedDigit().foregroundStyle(.secondary)
                }
            }

            // 播放控制：五等分，播放键居中突出
            HStack(spacing: 0) {
                controlButton {
                    playerService.togglePlayMode()
                } icon: {
                    Image(systemName: playerService.playMode.icon)
                        .font(.system(size: 13))
                }
                .help(playerService.playMode.displayName)

                controlButton {
                    playerService.previous()
                } icon: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15))
                }
                .help("上一首")

                controlButton {
                    playerService.togglePlayPause()
                } icon: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .frame(height: 26)
                }
                .help(playerService.isPlaying ? "暂停" : "播放")
                .keyboardShortcut(.space, modifiers: [])

                controlButton {
                    playerService.next()
                } icon: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                }
                .help("下一首")

                controlButton {
                    playerService.toggleFavorite()
                } icon: {
                    Image(systemName: playerService.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 13))
                        .foregroundStyle(playerService.isFavorite ? Color.accentColor : Color.secondary)
                }
                .help(playerService.isFavorite ? "取消收藏" : "收藏")
            }
            .padding(.top, 4)
        }
    }

    /// 等分宽度的控制按钮
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

    // MARK: - 歌词区

    private var lyricsPanel: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if playerService.lyricLines.isEmpty {
                        Text("播放歌曲并在此处查看歌词。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(playerService.lyricLines.enumerated()), id: \.offset) { index, line in
                            lyricRow(index: index, text: line.text, time: line.time)
                                .id(index)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.trailing, 8)
            }
            .scrollIndicators(.never)
            .onChange(of: playerService.currentLyricIndex) { index in
                guard index >= 0 else { return }
                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onAppear {
                let index = playerService.currentLyricIndex
                if index >= 0 {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
        }
    }

    private func lyricRow(index: Int, text: String, time: TimeInterval) -> some View {
        let isCurrent = index == playerService.currentLyricIndex
        return Button {
            playerService.seekTo(position: time)
        } label: {
            Text(text)
                .font(.system(
                    size: isCurrent ? 20 : 15,
                    weight: isCurrent ? .semibold : .regular
                ))
                .foregroundStyle(isCurrent ? Color.primary : Color.secondary.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("跳转到这句")
    }

    private var backdrop: some View {
        ZStack {
            VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
            Color.black.opacity(0.12)
        }
        .ignoresSafeArea()
    }

    private static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "--:--" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// 毛玻璃背景（NSVisualEffectView 的 SwiftUI 封装）
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
