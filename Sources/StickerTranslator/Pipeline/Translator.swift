import FoundationModels

struct StickerTranslation: Sendable, Equatable {
    let literal: String
    let meaning: String
}

enum TranslatorError: Error, CustomStringConvertible {
    case unreadableReply(String)
    case simulated
    var description: String {
        switch self {
        case .unreadableReply(let reply): "The model's reply couldn't be read: \(reply)"
        case .simulated: "Simulated failure (--simulate-failure)"
        }
    }
}

/// Asks Apple's on-device model for a literal translation and the real meaning.
/// Runs one request at a time.
actor Translator {
    private let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)
    private let glossary: SlangGlossary
    /// Dev flag `--simulate-failure`: the first attempt for each text fails, so Retry can be tried.
    private let simulateFailure = CommandLine.arguments.contains("--simulate-failure")
    private var failedOnce: Set<String> = []

    init(glossary: SlangGlossary = .shared) {
        self.glossary = glossary
    }

    static let instructions = """
    You are a friendly bilingual Mexican Spanish tutor. The user received a sticker in a WhatsApp chat \
    and wants to understand it. You get the sticker text and, sometimes, slang notes from a trusted glossary. \
    Trust the glossary notes over your own guesses. Stickers often misspell words on purpose to be cute or funny \
    ("ola wen dia" for "hola, buen día"): read them as the intended Spanish, and mention the playful spelling \
    in MEANING when it's part of the joke.
    Always answer with exactly these two lines and nothing else:
    LITERAL: <word-for-word English translation of the whole sticker; never copy the Spanish>
    MEANING: <one short sentence: what the sender really means and the tone>

    For example, for the sticker text "qué padre, ya es viernes" your whole answer is:
    LITERAL: How father, it's already Friday
    MEANING: "Awesome, it's finally Friday!" — excited and happy.
    """

    func translate(_ text: String) async throws -> StickerTranslation {
        if simulateFailure, failedOnce.insert(text).inserted { throw TranslatorError.simulated }
        let matches = glossary.matches(in: text)
        let notes = matches.map { "\"\($0.phrase)\" = \($0.note)" }
        var prompt = "Sticker text: \"\(text)\""
        if !notes.isEmpty {
            prompt += "\nGlossary notes: " + notes.joined(separator: " ")
        }
        if matches.contains(where: { $0.playful == true }) {
            prompt += "\nThis sticker misspells words on purpose to be cute or funny. "
                + "LITERAL is still the English translation of the intended Spanish. "
                + "The MEANING line must say the spelling is deliberate, for example: a cutesy, deliberately misspelled \"good morning\"."
        }
        prompt += "\nAnswer with the LITERAL: line, then the MEANING: line."
        let first = try await ask(prompt)
        // The small model sometimes copies the Spanish into LITERAL; ask once more if it did.
        guard SlangGlossary.normalize(first.literal) == SlangGlossary.normalize(text) else { return first }
        let retry = try? await ask(prompt + "\nLITERAL must be in English. Do not copy the Spanish text.")
        return retry ?? first
    }

    private func ask(_ prompt: String) async throws -> StickerTranslation {
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
