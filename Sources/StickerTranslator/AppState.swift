import AppKit
import Observation

/// The app's shared state: the toggle and the readiness status.
@MainActor
@Observable
final class AppState {
    var readiness: Readiness = .check()

    var isTranslating = false {
        didSet {
            guard isTranslating != oldValue else { return }
            if isTranslating && readiness != .ready { isTranslating = false }
        }
    }

    @ObservationIgnored private var timer: Timer?

    init() {
        // Re-check every few seconds so the status follows permission changes and WhatsApp opening or quitting.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func refresh() {
        readiness = .check()
        if readiness != .ready { isTranslating = false }
    }

    func requestScreenPermission() {
        // Shows the system prompt the first time; afterwards, the setting lives in System Settings.
        if !CGRequestScreenCaptureAccess(),
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
