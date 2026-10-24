import SwiftUI

/// 主窗口壁纸背景
struct MacWallpaperBackdrop: View {
    @EnvironmentObject var appearance: AppearanceSettings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            if let image = appearance.wallpaperImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blur(radius: appearance.wallpaperBlur)
                    .overlay(
                        Color.black.opacity(
                            min(0.9, appearance.wallpaperDim + (colorScheme == .dark ? 0.18 : 0.18))
                        )
                    )
                    .overlay(.ultraThinMaterial.opacity(0.35))
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .ignoresSafeArea()
    }
}
