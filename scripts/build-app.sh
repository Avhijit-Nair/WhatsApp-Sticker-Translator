#!/usr/bin/env bash
# Builds the Swift package and wraps it into build/StickerTranslator.app (ad hoc signed).
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)/StickerTranslator"

APP="build/StickerTranslator.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/StickerTranslator"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Sources/StickerTranslator/Pipeline/slang-glossary.json "$APP/Contents/Resources/"

codesign --force --sign - --identifier dev.stickertranslator.app "$APP"
echo "Built $APP"
