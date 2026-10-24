import SwiftUI

/// 通用音乐列表（macOS）
struct MacMusicListView: View {
    enum Mode { case ranking, latest }

    @EnvironmentObject var playerService: AudioPlayerService
    let title: String
    let mode: Mode

    @State private var musics: [Music] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载中…").controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if musics.isEmpty {
                ContentUnavailableView("暂无内容", systemImage: "music.note")
            } else {
                List {
                    ForEach(Array(musics.enumerated()), id: \.element.id) { index, music in
                        Button {
                            playerService.setPlaylist(musics, startAt: index)
                        } label: {
                            HStack(spacing: 12) {
                                MacCover(musicId: music.id, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(music.title).lineLimit(1)
                                    Text(music.artist)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if playerService.currentMusic?.id == music.id {
                                    Image(systemName: playerService.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                                        .foregroundStyle(.tint)
                                }
                                Text(Self.format(music.duration))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.bottom, 84)
        .navigationTitle(title)
        .task { await load() }
    }

    private func load() async {
        do {
            let result = mode == .ranking
                ? try await MusicService.shared.getRanking()
                : try await MusicService.shared.getLatest()
            await MainActor.run {
                self.musics = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }

    static func format(_ seconds: Int) -> String {
        guard seconds > 0 else { return "--:--" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
