import SwiftUI

/// 底部浮动播放条（参考 Apple Music macOS）
struct MacMiniPlayerBar: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @Binding var showNowPlaying: Bool
    @Environment(\.openWindow) private var openWindow
    @State private var tint: Color?

    var body: some View {
        HStack(spacing: 16) {
            Button {
                openWindow(id: "now-playing")
            } label: {
                HStack(spacing: 10) {
                    MacCover(musicId: playerService.currentMusic?.id ?? 0, size: 36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(playerService.currentMusic?.title ?? "未在播放")
                            .font(.callout)
                            .lineLimit(1)
                        Text(playerService.currentMusic?.artist ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 180, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)

            Spacer(minLength: 12)

            HStack(spacing: 22) {
                Button { playerService.previous() } label: {
                    Image(systemName: "backward.fill")
                }
                .buttonStyle(.borderless)

                Button { playerService.togglePlayPause() } label: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .imageScale(.large)
                        .frame(width: 28, height: 22)
                }
                .keyboardShortcut(.space, modifiers: [])
                .buttonStyle(.borderless)

                Button { playerService.next() } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.borderless)
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Text(Self.format(playerService.currentPosition))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                NativeSlider(
                    value: Binding(
                        get: { min(playerService.currentPosition, max(playerService.duration, 0.1)) },
                        set: { playerService.seekTo(position: $0) }
                    ),
                    range: 0...max(playerService.duration, 0.1),
                    controlSize: .small,
                    accessibilityLabel: "播放进度"
                )
                .frame(width: 200, height: 18)

                Text(Self.format(playerService.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Button { playerService.toggleFavorite() } label: {
                Image(systemName: playerService.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(playerService.isFavorite ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    if let tint {
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.35), tint.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .contentShape(Capsule())
        .onTapGesture(count: 2) {
            openWindow(id: "now-playing")
        }
        .task(id: playerService.currentMusic?.id) {
            let urlString = APIConfig.buildMusicCoverURL(
                musicId: playerService.currentMusic?.id ?? 0,
                coverFilePath: playerService.currentMusic?.coverFilePath
            )
            guard let url = URL(string: urlString),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data) else {
                tint = nil
                return
            }
            tint = DominantColor.color(of: image)
        }
    }

    private static func format(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// 封面加载（macOS 版）
struct MacCover: View {
    let musicId: Int
    let size: CGFloat
    /// true 时按容器宽度自适应（卡片用），false 时固定 size（播放条用）
    var flexible: Bool = false
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: flexible ? nil : size, height: flexible ? nil : size)
        .frame(maxWidth: flexible ? .infinity : nil)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: max(4, size * 0.1), style: .continuous))
        .task(id: musicId) {
            await load()
        }
    }

    private func load() async {
        guard musicId > 0 else { return }
        let urlString = APIConfig.buildMusicCoverURL(musicId: musicId, coverFilePath: nil)
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = NSImage(data: data) {
                await MainActor.run { self.image = img }
            }
        } catch {
            // 忽略封面失败
        }
    }
}
