import AppKit
import SwiftUI

/// 真·原生 NSSlider：不用 SwiftUI 的 Slider，保证 100% 系统外观与行为
struct NativeSlider: NSViewRepresentable {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var controlSize: NSControl.ControlSize = .small
    var accessibilityLabel: String?
    var onEditingChanged: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(
            value: value,
            minValue: range.lowerBound,
            maxValue: range.upperBound,
            target: context.coordinator,
            action: #selector(Coordinator.valueChanged(_:))
        )
        slider.controlSize = controlSize
        slider.isContinuous = true
        if let accessibilityLabel {
            slider.setAccessibilityLabel(accessibilityLabel)
        }
        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        context.coordinator.parent = self
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.controlSize = controlSize
        if let accessibilityLabel {
            slider.setAccessibilityLabel(accessibilityLabel)
        }
        // 拖动中不要回写，避免跳动
        if !context.coordinator.isEditing, abs(slider.doubleValue - value) > 0.001 {
            slider.doubleValue = value
        }
    }

    final class Coordinator: NSObject {
        var parent: NativeSlider
        var isEditing = false

        init(_ parent: NativeSlider) {
            self.parent = parent
        }

        @objc func valueChanged(_ sender: NSSlider) {
            parent.value = sender.doubleValue
        }
    }
}
