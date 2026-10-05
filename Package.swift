// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StickerTranslator",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "StickerTranslator",
            resources: [.copy("Pipeline/slang-glossary.json")]
        )
    ]
)
