import Foundation

/// A curated list of Mexican slang notes, bundled with the app.
/// Matching notes are fed to the Translator so the on-device model explains slang correctly.
struct SlangGlossary: Sendable {
    struct Entry: Codable, Sendable {
        let phrase: String
        let variants: [String]
        let note: String
    }

    let entries: [Entry]

    static let shared = SlangGlossary.loadBundled()

    static func loadBundled() -> SlangGlossary {
        // Inside the .app, scripts/build-app.sh copies the file into Contents/Resources;
        // under `swift run`, SwiftPM's resource bundle has it.
        let url = Bundle.main.url(forResource: "slang-glossary", withExtension: "json")
            ?? Bundle.module.url(forResource: "slang-glossary", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return SlangGlossary(entries: [])
        }
        return SlangGlossary(entries: entries)
    }

    /// Entries whose phrase or variant appears as whole words in `text`.
    /// A shorter match inside a longer one ("oso" inside "qué oso") is dropped.
    func matches(in text: String) -> [Entry] {
        let haystack = " \(Self.normalize(text)) "
        var found: [(entry: Entry, form: String)] = []
        for entry in entries {
            let forms = ([entry.phrase] + entry.variants).map(Self.normalize).filter { !$0.isEmpty }
            if let form = forms.sorted(by: { $0.count > $1.count }).first(where: { haystack.contains(" \($0) ") }) {
                found.append((entry, form))
            }
        }
        return found
            .filter { candidate in
                !found.contains { other in
                    other.form != candidate.form && other.form.count > candidate.form.count
                        && " \(other.form) ".contains(" \(candidate.form) ")
                }
            }
            .map(\.entry)
    }

    /// Lowercased, accents and punctuation removed, whitespace collapsed.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
        let cleaned = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(cleaned).split(separator: " ").joined(separator: " ")
    }
}
