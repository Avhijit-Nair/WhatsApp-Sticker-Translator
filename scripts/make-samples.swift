// Generates public-safe sample sticker PNGs into samples/.
// Run: swift scripts/make-samples.swift
import AppKit

struct Sample { let file: String; let lines: [String]; let font: String; let color: NSColor }

let samples = [
    Sample(file: "no-manches.png", lines: ["¡NO MANCHES", "GÜEY!"], font: "Impact", color: .systemOrange),
    Sample(file: "que-oso.png", lines: ["qué oso"], font: "Marker Felt Wide", color: .systemPink),
    Sample(file: "ando-crudo.png", lines: ["ANDO BIEN", "CRUDO"], font: "Chalkboard SE Bold", color: .systemTeal),
    Sample(file: "te-quiero.png", lines: ["te quiero", "un chingo"], font: "Noteworthy Bold", color: .systemRed),
    Sample(file: "me-vale.png", lines: ["ME VALE"], font: "Futura Condensed ExtraBold", color: .systemPurple),
    Sample(file: "ola-wen-dia.png", lines: ["OLA WEN", "DIA"], font: "Chalkboard SE Bold", color: .systemBlue),
    Sample(file: "english.png", lines: ["GOOD MORNING", "SUNSHINE"], font: "Impact", color: .systemYellow),
    Sample(file: "no-text.png", lines: [], font: "Impact", color: .systemGreen),
]

let size = NSSize(width: 512, height: 512)
let outDir = URL(fileURLWithPath: "samples", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for sample in samples {
    let image = NSImage(size: size, flipped: false) { rect in
        // A blobby colored "sticker" with a white border.
        let blob = NSBezierPath(ovalIn: rect.insetBy(dx: 24, dy: 60))
        NSColor.white.setFill(); blob.fill()
        sample.color.setFill(); NSBezierPath(ovalIn: rect.insetBy(dx: 36, dy: 72)).fill()
        NSColor.black.withAlphaComponent(0.25).setFill()
        NSBezierPath(ovalIn: NSRect(x: 196, y: 300, width: 40, height: 40)).fill()
        NSBezierPath(ovalIn: NSRect(x: 276, y: 300, width: 40, height: 40)).fill()

        let font = NSFont(name: sample.font, size: 72) ?? .boldSystemFont(ofSize: 72)
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: NSColor.white, .paragraphStyle: style,
            .strokeColor: NSColor.black, .strokeWidth: -4,
        ]
        let lineHeight: CGFloat = 80
        let top = rect.midY + CGFloat(sample.lines.count) * lineHeight / 2 - 40
        for (index, line) in sample.lines.enumerated() {
            let y = top - CGFloat(index) * lineHeight - lineHeight / 2
            line.draw(in: NSRect(x: 0, y: y - 40, width: rect.width, height: 100), withAttributes: attributes)
        }
        return true
    }
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    try rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent(sample.file))
    print("wrote samples/\(sample.file)")
}
