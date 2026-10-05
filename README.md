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

## Try the pipeline without WhatsApp
```sh
swift run StickerTranslator --check samples/*.png
```
This reads the text in each image, checks that it's Spanish, and prints LITERAL and MEANING. `swift scripts/make-samples.swift` regenerates the sample stickers.

## How it understands slang
Apple's on-device model is small and often guesses Mexican slang wrong ("qué oso" → "How cool!" instead of "How embarrassing!"). So the app ships a curated glossary, `Sources/StickerTranslator/Pipeline/slang-glossary.json`. Notes for any slang it finds go into the prompt. Phrases outside the glossary fall back to the model's own knowledge. Add entries freely.
