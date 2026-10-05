import SwiftUI

/// The dark floating tooltip shown beside a sticker.
struct TooltipView: View {
    let state: TranslationCache.State

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
                section("LITERAL", translation.literal)
                section("MEANING", translation.meaning)
            case .failed:
                Text("Couldn't translate this sticker.")
                    .font(.system(size: 13))
                    .foregroundStyle(Self.softRed)
            case .closed:
                EmptyView()
            }
        }
        .frame(maxWidth: 236, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .background(Self.background, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        .padding(8) // room for the shadow inside the panel
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
