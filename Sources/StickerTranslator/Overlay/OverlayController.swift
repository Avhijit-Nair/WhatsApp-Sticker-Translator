import AppKit
import SwiftUI

/// Keeps one small floating panel per visible Spanish sticker and moves it beside the sticker's text.
@MainActor
final class OverlayController {
    private var panels: [String: NSPanel] = [:]
    private let gap: CGFloat = 12
    var onClose: (String) -> Void = { _ in }
    var onRetry: (String) -> Void = { _ in }

    /// Shows a tooltip for each `(key, state, rect)` and hides the rest.
    /// `rect` is the sticker text's position in AppKit screen coordinates.
    func show(_ items: [(key: String, state: TranslationCache.State, rect: CGRect)]) {
        let visibleKeys = Set(items.map(\.key))
        for (key, panel) in panels where !visibleKeys.contains(key) {
            panel.orderOut(nil)
        }
        for item in items {
            let panel = panels[item.key] ?? makePanel()
            panels[item.key] = panel
            let hosting = panel.contentView as! TooltipHostingView
            let key = item.key
            hosting.rootView = TooltipView(
                state: item.state,
                onClose: { [weak self] in self?.close(key) },
                onRetry: { [weak self] in self?.onRetry(key) }
            )
            let size = hosting.fittingSize
            panel.setFrame(placement(for: item.rect, size: size), display: true)
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    private func close(_ key: String) {
        panels.removeValue(forKey: key)?.close()
        onClose(key)
    }

    func removeAll() {
        panels.values.forEach { $0.close() }
        panels.removeAll()
    }

    /// Right of the text, vertically centered; on the left if there's no room on the right.
    private func placement(for rect: CGRect, size: CGSize) -> CGRect {
        let screen = NSScreen.screens.first { $0.frame.intersects(rect) } ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? .infinite
        var x = rect.maxX + gap
        if x + size.width > bounds.maxX { x = rect.minX - gap - size.width }
        var y = rect.midY - size.height / 2
        y = min(max(y, bounds.minY), bounds.maxY - size.height)
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.becomesKeyOnlyIfNeeded = true // clicking ✕ or Retry never takes focus from WhatsApp
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = TooltipHostingView(rootView: TooltipView(state: .translating))
        return panel
    }

    /// Converts a Vision box (normalized, bottom-left origin, relative to the snapshot)
    /// into AppKit screen coordinates (bottom-left origin of the main display).
    static func screenRect(for box: CGRect, in windowFrame: CGRect) -> CGRect {
        let mainHeight = NSScreen.screens.first?.frame.height ?? 0
        let topLeftY = windowFrame.minY + (1 - box.maxY) * windowFrame.height
        return CGRect(
            x: windowFrame.minX + box.minX * windowFrame.width,
            y: mainHeight - topLeftY - box.height * windowFrame.height,
            width: box.width * windowFrame.width,
            height: box.height * windowFrame.height
        )
    }
}

/// Lets ✕ and Retry respond to the first click, even though the tooltip panel never becomes active.
final class TooltipHostingView: NSHostingView<TooltipView> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
