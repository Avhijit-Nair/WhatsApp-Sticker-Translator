import NaturalLanguage

/// Decides whether a block's text is Spanish enough to translate.
enum LanguageFilter {
    static let threshold = 0.6

    /// `knownSlang` is true when the glossary matched. Short slang ("qué oso") and playful
    /// misspellings ("ola wen dia") fool the recognizer, so a match is enough unless the text is clearly English.
    static func isSpanish(_ text: String, knownSlang: Bool) -> Bool {
        guard text.filter(\.isLetter).count >= 2 else { return false }
        let hypotheses = hypotheses(for: text)
        if (hypotheses[.spanish] ?? 0) >= threshold { return true }
        return knownSlang && (hypotheses[.english] ?? 0) < 0.5
    }

    static func spanishConfidence(_ text: String) -> Double {
        hypotheses(for: text)[.spanish] ?? 0
    }

    private static func hypotheses(for text: String) -> [NLLanguage: Double] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.languageHypotheses(withMaximum: 5)
    }
}
