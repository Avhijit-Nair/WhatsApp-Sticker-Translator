import CoreGraphics
import Vision

/// One sticker's worth of text: nearby lines grouped together.
struct TextBlock: Sendable {
    let text: String
    /// Vision's normalized coordinates (0–1, origin at bottom-left of the image).
    let box: CGRect
}

/// Reads all text in an image and groups lines that sit close together into blocks.
enum TextFinder {
    static func blocks(in image: CGImage) throws -> [TextBlock] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es-ES", "en-US"]
        request.usesLanguageCorrection = false // keeps slang spellings as written
        try VNImageRequestHandler(cgImage: image).perform([request])

        let lines = (request.results ?? []).compactMap { observation -> TextBlock? in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence > 0.3 else { return nil }
            return TextBlock(text: candidate.string, box: observation.boundingBox)
        }
        return group(lines.filter { !isChatChrome($0.text) })
    }

    /// WhatsApp draws the message time and ✓✓ ticks on the sticker's corner ("7:58 pm ✓✓",
    /// often read as "7:58pm j"). Left in, they change the sticker's text from frame to frame.
    static func isChatChrome(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.filter(\.isLetter).count <= 1 { return true }
        return trimmed.range(of: #"^\d{1,2}[:.]\d{2}\s*([ap]\.?\s?m\.?)?\W*\w?\W*$"#,
                             options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Joins lines whose boxes are vertically close and horizontally overlapping.
    static func group(_ lines: [TextBlock]) -> [TextBlock] {
        var groups: [[TextBlock]] = []
        for line in lines.sorted(by: { $0.box.maxY > $1.box.maxY }) {
            if let index = groups.firstIndex(where: { $0.contains { belongTogether($0.box, line.box) } }) {
                groups[index].append(line)
            } else {
                groups.append([line])
            }
        }
        return groups.map { members in
            let ordered = members.sorted { $0.box.maxY > $1.box.maxY }
            let box = ordered.dropFirst().reduce(ordered[0].box) { $0.union($1.box) }
            return TextBlock(text: ordered.map(\.text).joined(separator: " "), box: box)
        }
    }

    private static func belongTogether(_ a: CGRect, _ b: CGRect) -> Bool {
        let lineHeight = max(a.height, b.height)
        let verticalGap = max(0, max(a.minY, b.minY) - min(a.maxY, b.maxY))
        let horizontalGap = max(0, max(a.minX, b.minX) - min(a.maxX, b.maxX))
        return verticalGap < lineHeight * 1.2 && horizontalGap < lineHeight
    }
}
