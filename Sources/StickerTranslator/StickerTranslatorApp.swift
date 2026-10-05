import SwiftUI

@main
enum StickerTranslatorMain {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.first == "--check" {
            Task { exit(await DevCheck.run(Array(arguments.dropFirst()))) }
            dispatchMain()
        }
        if arguments.first == "--status" {
            MainActor.assumeIsolated { print(Readiness.check()) }
            exit(0)
        }
        StickerTranslatorApp.main()
    }
}

/// A menu-bar app (no Dock icon) with a small control panel window.
struct StickerTranslatorApp: App {
    @State private var state = AppState()

    var body: some Scene {
        Window("Sticker Translator", id: "panel") {
            ControlPanelView(state: state)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Sticker Translator", systemImage: state.isTranslating ? "character.bubble.fill" : "character.bubble") {
            MenuContent(state: state)
        }
    }
}

private struct MenuContent: View {
    let state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(state.isTranslating ? "Translating stickers" : "Not translating")
        Button("Open Control Panel") {
            openWindow(id: "panel")
            NSApp.activate()
        }
        Divider()
        Button("Quit Sticker Translator") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
