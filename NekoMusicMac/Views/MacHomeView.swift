import SwiftUI

/// macOS 主页：封面主导的卡片网格，悬停有反馈
struct MacHomeView: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @State private var ranking: [Music] = []
    @State private var latest: [Music] = []
    @State private var isLoading = true

    private let columns = [GridItem(.adaptive(minimum: 156, maximum: 200), spacing: 22)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    section(title: "热门排行", subtitle: "大家都在听", musics: Array(ranking.prefix(10)))
                    section(title: "最新上架", subtitle: "刚入库的曲目", musics: Array(latest.prefix(20)))
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("主页")
        .task { await load() }
    }

    private func section(title: String, subtitle: String, musics: [Music]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(musics) { music in
                    MacMusicCard(
                        music: music,
                        isPlaying: playerService.currentMusic?.id == music.id && playerService.isPlaying
                    ) {
                        playerService.setPlaylist(musics, startAt: musics.firstIndex(of: music) ?? 0)
                    }
                }
            }
        }
    }

    private func load() async {
        do {
            let r = try await MusicService.shared.getRanking()
            let l = try await MusicService.shared.getLatest()
            await MainActor.run {
                self.ranking = r
                self.latest = l
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}

/// 单张音乐卡片：悬停放大 + 阴影 + 播放按钮浮现
struct MacMusicCard: View {
    let music: Music
    let isPlaying: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    MacCover(musicId: music.id, size: 180, flexible: true)
                        .shadow(
                            color: .black.opacity(isHovering ? 0.34 : 0.18),
                            radius: isHovering ? 16 : 8,
                            y: isHovering ? 10 : 5
                        )

                    // 播放按钮浮现
                    Image(systemName: isPlaying ? "waveform" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 0.5))
                        .padding(8)
                        .opacity(isHovering || isPlaying ? 1 : 0)
                        .scaleEffect(isHovering || isPlaying ? 1 : 0.8)
                        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isHovering)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(music.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(music.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .scaleEffect(isHovering ? 1.035 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
