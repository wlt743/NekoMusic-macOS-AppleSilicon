import AppKit
import SwiftUI

/// 从图片提取主色调（缩小到 1×1 取平均色，够用且极快）
enum DominantColor {
    private static let cache = NSCache<NSString, NSColor>()

    static func color(of image: NSImage?) -> Color? {
        guard let image else { return nil }
        if let cached = cache.object(forKey: NSString(string: String(describing: ObjectIdentifier(image)))) {
            return Color(nsColor: cached)
        }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let cg = rep.cgImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        let r = CGFloat(pixel[0]) / 255
        let g = CGFloat(pixel[1]) / 255
        let b = CGFloat(pixel[2]) / 255
        // 稍微提亮，避免背景太黑
        let color = NSColor(red: min(1, r * 1.25), green: min(1, g * 1.25), blue: min(1, b * 1.25), alpha: 1)
        cache.setObject(color, forKey: NSString(string: String(describing: ObjectIdentifier(image))))
        return Color(nsColor: color)
    }
}
