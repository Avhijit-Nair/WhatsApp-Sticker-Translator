import NaturalLanguage

/// Decides whether a block's text is Spanish enough to translate.
enum LanguageFilter {
    static let threshold = 0.6

    /// `knownSlang` is true when the glossary matched; short slang ("qué oso")
    /// often fools the recognizer, so a match lowers the bar.
    static func isSpanish(_ text: String, knownSlang: Bool) -> Bool {
        guard text.filter(\.isLetter).count >= 2 else { return false }
        return spanishConfidence(text) >= (knownSlang ? 0.15 : threshold)
    }

    static func spanishConfidence(_ text: String) -> Double {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.languageHypotheses(withMaximum: 5)[.spanish] ?? 0
    }
}
