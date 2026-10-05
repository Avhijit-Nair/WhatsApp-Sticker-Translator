import CoreGraphics
import ScreenCaptureKit

/// One snapshot of WhatsApp's window and where that window was on screen.
struct WindowSnapshot: @unchecked Sendable {
    let image: CGImage
    /// Screen position of the window in global display coordinates (origin top-left of the main display).
    let windowFrame: CGRect
}

/// Captures only WhatsApp's main window, so our own tooltips never appear in the snapshot.
enum WindowWatcher {
    /// Returns nil when WhatsApp has no visible window (minimized, hidden, or quit).
    static func snapshot() async throws -> WindowSnapshot? {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        let candidates = content.windows.filter {
            $0.owningApplication?.bundleIdentifier == Readiness.whatsAppBundleID
                && $0.windowLayer == 0 && $0.isOnScreen && $0.frame.width > 200 && $0.frame.height > 200
        }
        guard let window = candidates.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
            return nil
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        let scale = CGFloat(filter.pointPixelScale)
        configuration.width = Int(window.frame.width * scale)
        configuration.height = Int(window.frame.height * scale)
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        return WindowSnapshot(image: image, windowFrame: window.frame)
    }
}
