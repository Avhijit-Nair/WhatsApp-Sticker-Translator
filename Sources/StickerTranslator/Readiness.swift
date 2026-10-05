import AppKit
import CoreGraphics
import FoundationModels

/// Checks the three things the app needs before it can translate.
enum Readiness: Equatable, Sendable {
    case ready
    case needsScreenPermission
    case whatsAppNotOpen
    case modelUnavailable(String)

    static let whatsAppBundleID = "net.whatsapp.WhatsApp"

    /// Reports the first problem found, in the order the user should fix them.
    static func check() -> Readiness {
        if !CGPreflightScreenCaptureAccess() { return .needsScreenPermission }
        if !isWhatsAppRunning { return .whatsAppNotOpen }
        if case .unavailable(let reason) = SystemLanguageModel.default.availability {
            return .modelUnavailable(String(describing: reason))
        }
        return .ready
    }

    static var isWhatsAppRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: whatsAppBundleID).isEmpty
    }

    var message: String {
        switch self {
        case .ready: "Ready"
        case .needsScreenPermission: "Screen permission is required. Sticker Translator can't work until it's granted."
        case .whatsAppNotOpen: "WhatsApp Desktop isn't open."
        case .modelUnavailable(let reason): "Apple's on-device model isn't available (\(reason)). Check that Apple Intelligence is on."
        }
    }
}
