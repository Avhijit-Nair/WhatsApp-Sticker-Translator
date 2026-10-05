import Foundation

/// What we know about each sticker text, keyed by normalized text.
/// Makes tooltips reappear instantly after scrolling and keeps closed ones closed.
@MainActor
final class TranslationCache {
    enum State: Equatable {
        case translating
        case done(StickerTranslation)
        case failed(String)
        case closed
    }

    private var states: [String: State] = [:]
    private var spanishDecisions: [String: Bool] = [:]

    static func key(for text: String) -> String { SlangGlossary.normalize(text) }

    subscript(key: String) -> State? {
        get { states[key] }
        set { states[key] = newValue }
    }

    /// Runs the language check once per unique text.
    func isSpanish(_ text: String, key: String) -> Bool {
        if let known = spanishDecisions[key] { return known }
        let decision = LanguageFilter.isSpanish(text, knownSlang: !SlangGlossary.shared.matches(in: text).isEmpty)
        spanishDecisions[key] = decision
        return decision
    }
}
