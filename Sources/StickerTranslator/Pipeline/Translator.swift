import FoundationModels

struct StickerTranslation: Sendable, Equatable {
    let literal: String
    let meaning: String
}

enum TranslatorError: Error, CustomStringConvertible {
    case unreadableReply(String)
    var description: String {
        switch self {
        case .unreadableReply(let reply): "The model's reply couldn't be read: \(reply)"
        }
    }
}

/// Asks Apple's on-device model for a literal translation and the real meaning.
/// Runs one request at a time.
actor Translator {
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
    private let glossary: SlangGlossary

    init(glossary: SlangGlossary = .shared) {
        self.glossary = glossary
    }

    static let instructions = """
    You are a friendly bilingual Mexican Spanish tutor. The user received a sticker in a WhatsApp chat \
    and wants to understand it. You get the sticker text and, sometimes, slang notes from a trusted glossary. \
    Trust the glossary notes over your own guesses.
    Always answer with exactly these two lines and nothing else:
    LITERAL: <word-for-word English translation of the whole sticker; never copy the Spanish>
    MEANING: <one short sentence: what the sender really means and the tone>

    For example, for the sticker text "qué padre, ya es viernes" your whole answer is:
    LITERAL: How father, it's already Friday
    MEANING: "Awesome, it's finally Friday!" — excited and happy.
    """

    func translate(_ text: String) async throws -> StickerTranslation {
        let notes = glossary.matches(in: text).map { "\"\($0.phrase)\" = \($0.note)" }
        var prompt = "Sticker text: \"\(text)\""
        if !notes.isEmpty {
            prompt += "\nGlossary notes: " + notes.joined(separator: " ")
        }
        prompt += "\nAnswer with the LITERAL: line, then the MEANING: line."
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let reply = try await session.respond(to: prompt, options: GenerationOptions(temperature: 0.2)).content
        return try Self.parse(reply)
    }

    static func parse(_ reply: String) throws -> StickerTranslation {
        func value(after label: String) -> String? {
            reply.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first { $0.uppercased().hasPrefix(label) }
                .map { String($0.dropFirst(label.count)).trimmingCharacters(in: .whitespaces) }
                .flatMap { $0.isEmpty ? nil : $0 }
        }
        guard let literal = value(after: "LITERAL:"), let meaning = value(after: "MEANING:") else {
            throw TranslatorError.unreadableReply(reply)
        }
        return StickerTranslation(literal: literal, meaning: meaning)
    }
}
