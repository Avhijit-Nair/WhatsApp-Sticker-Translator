import AppKit

/// `StickerTranslator --check <image>...` — runs Text Finder → Language Filter → Translator
/// on image files and prints the result. A dev tool for checking the pipeline without WhatsApp.
enum DevCheck {
    static func run(_ paths: [String]) async -> Int32 {
        guard !paths.isEmpty else {
            print("usage: StickerTranslator --check <image> [<image>...]")
            return 2
        }
        let translator = Translator()
        var failures: Int32 = 0
        for path in paths {
            print("== \(path)")
            guard let image = NSImage(contentsOfFile: path)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                print("   couldn't open image"); failures += 1; continue
            }
            do {
                let blocks = try TextFinder.blocks(in: image)
                if blocks.isEmpty { print("   no text, skipped") }
                for block in blocks {
                    let slang = SlangGlossary.shared.matches(in: block.text)
                    let confidence = LanguageFilter.spanishConfidence(block.text)
                    print("   text: \"\(block.text)\"  (spanish \(String(format: "%.2f", confidence)), glossary: \(slang.map(\.phrase)))")
                    guard LanguageFilter.isSpanish(block.text, knownSlang: !slang.isEmpty) else {
                        print("   not Spanish, skipped"); continue
                    }
                    let result = try await translator.translate(block.text)
                    print("   LITERAL: \(result.literal)")
                    print("   MEANING: \(result.meaning)")
                }
            } catch {
                print("   failed: \(error)"); failures += 1
            }
        }
        return failures == 0 ? 0 : 1
    }
}
