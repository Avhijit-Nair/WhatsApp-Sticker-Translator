# Sticker Translator

A Mac menu-bar app that sits alongside WhatsApp Desktop and labels Spanish stickers with an English **literal** translation and what they really **mean**: the slang, the tone, the joke. Everything runs on-device; screenshots and chat content never leave the Mac.

## Requirements
- macOS 26 on Apple silicon, with **Apple Intelligence turned on** (for Apple's on-device Foundation Models)
- Swift 6.2 toolchain (Xcode Command Line Tools are enough)
- WhatsApp Desktop for Mac

## Run it
```sh
./scripts/run.sh
```
This builds `build/StickerTranslator.app`, signs it ad hoc, and opens it. The app has no Dock icon; it lives in the menu bar.

**First run:** click **Grant Screen Permission…** in the control panel and allow Sticker Translator under System Settings → Privacy & Security → **Screen & System Audio Recording**, then quit and reopen the app. Because each build is signed ad hoc, macOS may ask again after a rebuild.

## Using it
1. Open WhatsApp Desktop, then Sticker Translator. When the status dot is green, turn on **Always translate images**. The panel steps aside and WhatsApp comes to the front.
2. Chat as usual. A Spanish sticker gets a dark tooltip beside it: "Translating… please wait a moment," then **LITERAL** and **MEANING**.
3. Scroll and the tooltips follow; they hide when their sticker leaves the screen. **✕** closes a tooltip for the rest of the session. If a translation fails, **↻ Retry** tries again.
4. Reopen the panel or quit from the speech-bubble icon in the menu bar.

Tooltips only show while WhatsApp is the front app, so they never float over other windows.

## Privacy
Everything happens on the Mac: ScreenCaptureKit captures only WhatsApp's window, Vision reads the text, NaturalLanguage checks it's Spanish, and Apple's on-device Foundation Models writes the translation. Nothing is saved to disk and nothing is sent anywhere. It works with Wi-Fi off.

## Try the pipeline without WhatsApp
```sh
swift run StickerTranslator --check samples/*.png
```
This reads the text in each image, checks that it's Spanish, and prints LITERAL and MEANING. `swift scripts/make-samples.swift` regenerates the sample stickers.

## How it understands slang
Apple's on-device model is small and often guesses Mexican slang wrong ("qué oso" → "How cool!" instead of "How embarrassing!"). So the app ships a curated glossary, `Sources/StickerTranslator/Pipeline/slang-glossary.json`. Notes for any slang it finds go into the prompt. Phrases outside the glossary fall back to the model's own knowledge. Add entries freely.

Stickers often misspell words on purpose ("ola wen dia" for "hola, buen día"). Entries flagged `"playful": true` tell the model to read the intended Spanish and point out the joke.

## Known limitations
- **Any Spanish text in the WhatsApp window counts,** including text messages and chat-list previews, not just text inside stickers.
- **Stickers without readable text, or with very stylized lettering,** may be missed. Small or low-resolution images can lose letters.
- **Short non-Spanish text in Latin letters** (for example Hindi written in English letters) can be mistaken for Spanish.
- **Slang outside the glossary** relies on the small on-device model, which can guess wrong.
- **Identical stickers share one tooltip state,** and closed tooltips come back after a relaunch.
- **Tooltips trail slightly behind fast scrolling.** The app re-scans about 3 times per second instead of tracking motion.

## Dev flags
- `--check <image>...` runs the pipeline on image files and prints the result.
- `open build/StickerTranslator.app --args --start` turns the toggle on at launch.
- `open build/StickerTranslator.app --args --simulate-failure` makes each sticker's first translation fail, to try ↻ Retry.
- `./scripts/make-dev-cert.sh` (optional, once) creates a local signing identity so macOS keeps the screen permission across rebuilds.

## Built with
Swift 6, SwiftUI + AppKit, ScreenCaptureKit, Vision, NaturalLanguage, and Foundation Models, all part of macOS 26. No third-party dependencies.
