import SwiftUI
import AppKit

/// macOS 外观设置：主题色、深浅色、壁纸、歌词字号
struct MacSettingsView: View {
    @StateObject private var appearance = AppearanceSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showImporter = false
    @State private var showDesktopLyrics = DesktopLyricsController.shared.isVisible

    var body: some View {
        Form {
            Section("外观模式") {
                Picker("模式", selection: $appearance.appearanceMode) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("主题色") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 14)], spacing: 14) {
                    ForEach(ThemeOption.all) { option in
                        Button {
                            appearance.themeID = option.id
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if appearance.themeID == option.id {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                Text(option.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)

                ColorPicker("自定义颜色", selection: Binding(
                    get: { appearance.customColor },
                    set: { appearance.setCustomColor($0) }
                ), supportsOpacity: false)
            }

            Section("壁纸") {
                HStack(spacing: 12) {
                    if let image = appearance.wallpaperImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 64, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button("选择图片…") { showImporter = true }
                    Spacer()
                    if appearance.wallpaperImage != nil {
                        Button("移除", role: .destructive) {
                            appearance.clearWallpaper()
                        }
                    }
                }

                Slider(value: $appearance.wallpaperBlur, in: 0...30) {
                    Text("模糊 \(Int(appearance.wallpaperBlur))")
                }

                Slider(value: $appearance.wallpaperDim, in: 0...0.9) {
                    Text("遮罩 \(Int(appearance.wallpaperDim * 100))%")
                }
            }

            Section("歌词") {
                Slider(value: $appearance.lyricFontSize, in: 14...28) {
                    Text("字号 \(Int(appearance.lyricFontSize))")
                }

                Toggle("桌面歌词悬浮窗", isOn: $showDesktopLyrics)
                    .onChange(of: showDesktopLyrics) { enabled in
                        if enabled {
                            DesktopLyricsController.shared.show(
                                player: AudioPlayerService.shared,
                                appearance: appearance
                            )
                        } else {
                            DesktopLyricsController.shared.hide()
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("外观")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("完成") { dismiss() }
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            if let image = NSImage(contentsOf: url) {
                appearance.setWallpaper(image)
            }
        }
    }
}
