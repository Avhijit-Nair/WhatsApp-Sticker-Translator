import SwiftUI

/// The dark floating tooltip shown beside a sticker: loading, translated, or error, with ✕ to close.
struct TooltipView: View {
    let state: TranslationCache.State
    var onClose: () -> Void = {}
    var onRetry: () -> Void = {}

    private static let background = Color(red: 0x1B / 255, green: 0x1F / 255, blue: 0x24 / 255).opacity(0.92)
    private static let teal = Color(red: 0x9F / 255, green: 0xE3 / 255, blue: 0xD6 / 255)
    private static let softRed = Color(red: 0xFF / 255, green: 0xB4 / 255, blue: 0xB4 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch state {
            case .translating:
                Text("Translating… please wait a moment.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            case .done(let translation):
                if Self.saysTheSame(translation) {
                    section("TRANSLATION", translation.meaning)
                } else {
                    section("LITERAL", translation.literal)
                    section("MEANING", translation.meaning)
                }
            case .failed:
                Text("Couldn't translate this sticker.")
                    .font(.system(size: 13))
                    .foregroundStyle(Self.softRed)
                Button(action: onRetry) {
                    Text("↻ Retry").font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .foregroundStyle(.white)
                .background(.white.opacity(0.15), in: Capsule())
            case .closed:
                EmptyView()
            }
        }
        .padding(.trailing, 14) // keeps text clear of the ✕
        .frame(maxWidth: 236, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .background(Self.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(5)
        }
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        .padding(8) // room for the shadow inside the panel
    }

    /// Plain, non-slang text: when literal and meaning say the same thing, show one line.
    static func saysTheSame(_ translation: StickerTranslation) -> Bool {
        let literal = SlangGlossary.normalize(translation.literal)
        let meaning = SlangGlossary.normalize(translation.meaning)
        return literal == meaning || meaning.hasPrefix(literal) && meaning.count - literal.count < 4
    }

    private func section(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Self.teal)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
