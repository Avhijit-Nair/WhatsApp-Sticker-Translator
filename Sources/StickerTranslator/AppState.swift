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
            if isTranslating && readiness != .ready { isTranslating = false; return }
            if isTranslating {
                pipeline.start()
                stepAside()
            } else {
                pipeline.stop()
            }
        }
    }

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private let pipeline = LivePipeline()

    init() {
        // Re-check every few seconds so the status follows permission changes and WhatsApp opening or quitting.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        // Dev shortcut: `open build/StickerTranslator.app --args --start` turns the toggle on at launch.
        if CommandLine.arguments.contains("--start") {
            Task { self.isTranslating = true }
        }
    }

    func refresh() {
        readiness = .check()
        if readiness != .ready { isTranslating = false }
    }

    /// After the toggle turns on, the panel gets out of the way and WhatsApp comes to the front.
    private func stepAside() {
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            NSApp.windows.first { $0.title == "Sticker Translator" }?.close()
            NSRunningApplication.runningApplications(withBundleIdentifier: Readiness.whatsAppBundleID).first?.activate()
        }
    }

    func requestScreenPermission() {
        // Shows the system prompt the first time; afterwards, the setting lives in System Settings.
        if !CGRequestScreenCaptureAccess(),
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
