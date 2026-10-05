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

# A stable identity keeps the screen permission across rebuilds (see scripts/make-dev-cert.sh).
IDENTITY="Sticker Translator Dev"
if ! security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    IDENTITY="-" # ad hoc: macOS may ask for screen permission again after each rebuild
fi
codesign --force --sign "$IDENTITY" --identifier dev.stickertranslator.app "$APP"
echo "Built $APP"
