import Foundation

@main
enum StickerTranslatorMain {
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.first == "--check" {
            exit(await DevCheck.run(Array(arguments.dropFirst())))
        }
        print("usage: StickerTranslator --check <image> [<image>...]")
    }
}
