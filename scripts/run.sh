#!/usr/bin/env bash
# Builds the app and opens it. Quits a running copy first.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-app.sh
pkill -x StickerTranslator 2>/dev/null && sleep 1 || true
open build/StickerTranslator.app
