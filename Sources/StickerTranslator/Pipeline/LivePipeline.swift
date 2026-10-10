import AppKit
import os

/// While running: snapshot WhatsApp ~3×/sec → find Spanish text → translate new text → place tooltips.
/// "Re-scan, don't track": each snapshot decides where every tooltip goes now.
@MainActor
final class LivePipeline {
    private let cache = TranslationCache()
    private let overlay = OverlayController()
    private let translator = Translator()
    private var loop: Task<Void, Never>?
    /// Text seen in the previous snapshot. New text must show up twice in a row before it's
    /// translated, so half-scrolled, partly read stickers don't each start a translation.
    private var previousKeys: Set<String> = []
    static let log = Logger(subsystem: "dev.stickertranslator.app", category: "pipeline")

    init() {
        overlay.onClose = { [weak self] key in
            self?.cache[key] = .closed
            Self.log.info("closed: \(key, privacy: .public)")
        }
        overlay.onRetry = { [weak self] key in
            guard let self, case .failed = cache[key] else { return }
            Self.log.info("retry: \(key, privacy: .public)")
            translate(key: key)
        }
    }

    func start() {
        guard loop == nil else { return }
        Self.log.info("pipeline started")
        loop = Task { [weak self] in
            while !Task.isCancelled {
                let started = ContinuousClock.now
                await self?.tick()
                try? await Task.sleep(until: started + .milliseconds(333))
            }
        }
    }

    func stop() {
        guard let running = loop else { return }
        running.cancel()
        loop = nil
        overlay.removeAll()
        Self.log.info("pipeline stopped")
    }

    private func tick() async {
        guard isWhatsAppInFront, let snapshot = try? await WindowWatcher.snapshot() else {
            overlay.show([])
            return
        }
        let image = snapshot.image
        let blocks = await Task.detached(priority: .userInitiated) { (try? TextFinder.blocks(in: image)) ?? [] }.value
        guard loop != nil else { return } // stopped while reading

        var items: [(key: String, state: TranslationCache.State, rect: CGRect)] = []
        var seenKeys: Set<String> = []
        for block in blocks {
            let key = TranslationCache.key(for: block.text)
            guard !key.isEmpty, cache.isSpanish(block.text, key: key) else { continue }
            seenKeys.insert(key)
            texts[key] = block.text
            if cache[key] == nil {
                guard previousKeys.contains(key) else { continue }
                translate(key: key)
            }
            guard let state = cache[key], state != .closed else { continue }
            items.append((key, state, OverlayController.screenRect(for: block.box, in: snapshot.windowFrame)))
        }
        previousKeys = seenKeys
        overlay.show(items)
        if !items.isEmpty {
            Self.log.debug("frame: \(blocks.count) blocks, tooltips: \(items.map { "\($0.key) @ \(Int($0.rect.minX)),\(Int($0.rect.minY))" }.joined(separator: "; "), privacy: .public)")
        }
    }

    /// Original (un-normalized) text for each key, for the model and for Retry.
    private var texts: [String: String] = [:]

    private func translate(key: String) {
        guard let text = texts[key] else { return }
        cache[key] = .translating
        Self.log.info("translating: \(key, privacy: .public)")
        Task {
            do {
                let translation = try await translator.translate(text)
                guard cache[key] != .closed else { return }
                cache[key] = .done(translation)
                Self.log.info("translated: \(key, privacy: .public)")
            } catch {
                guard cache[key] != .closed else { return }
                cache[key] = .failed(String(describing: error))
                Self.log.error("failed: \(key, privacy: .public) — \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// Tooltips only float while WhatsApp (or our own panel) is in front, so they never sit over other apps.
    private var isWhatsAppInFront: Bool {
        let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return front == Readiness.whatsAppBundleID || front == Bundle.main.bundleIdentifier
    }
}
