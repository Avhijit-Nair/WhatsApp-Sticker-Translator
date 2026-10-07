---
doc: checklist
status: approved
---

# Build Checklist

Build mode: learn

## Slices

- [x] **1. A sample sticker image goes in, and a literal translation plus its meaning come out**
  Becomes usable: `StickerTranslator --check samples/<image>.png` reads the Spanish text in a sticker image, confirms it's Spanish, and prints LITERAL and MEANING from Apple's on-device model. English or text-free images print "no Spanish text, skipped".
  Why now: This is the kernel and the biggest risk: is the on-device model good enough at explaining the joke? It also checks that Vision can read sticker fonts and that Foundation Models builds with this Mac's Command Line Tools (there's no full Xcode). If the meaning is weak, we tune the prompt before any overlay work. Scaffolding the SwiftPM package is part of this step.
  PRD ref: `prd.md > Translation Tooltip`, `prd.md > Automatic Detection`, `prd.md > Privacy`
  Spec ref: `spec.md > Text Finder`, `spec.md > Language Filter`, `spec.md > Translator`, `spec.md > Dev Check Tool`, `spec.md > File Structure`, `spec.md > Stack`
  Build: Create `Package.swift` (macOS 26 executable) and `.gitignore` entries for `build/` and `.build/`. Add `TextFinder.swift` (Vision OCR, es-ES + en-US, line grouping into blocks), `LanguageFilter.swift` (NLLanguageRecognizer, 0.6 threshold, at least 2 letters), `SlangGlossary.swift` + `slang-glossary.json` (about 60–100 curated Mexican slang notes), `Translator.swift` (`LanguageModelSession` with permissive guardrails, glossary notes in the prompt, two-line output parsed into `StickerTranslation`), and `DevCheck.swift`. Generate 4–6 public-safe sample sticker images in `samples/` (Mexican slang, one English, one no-text). The learner can add real ones.
  Verify (mechanical): `swift build` succeeds; `--check` on each sample prints a translation for the Spanish ones and "skipped" for the English and no-text ones; I read the meanings and judge whether they explain slang rather than repeating the literal text.
  Learner check: Run `swift run StickerTranslator --check samples/<file>` on a couple of samples (or a real sticker you save from WhatsApp) and judge: would this explanation actually help you get her joke?
  Commit: `Add on-device sticker translation pipeline with --check dev mode`

- [x] **2. The app launches as a menu-bar app with a control panel that knows if it's ready**
  Becomes usable: `./scripts/run.sh` builds and opens `StickerTranslator.app`. The control panel shows the toggle, "Language: Spanish → English," and a status line telling you if screen permission is missing, WhatsApp isn't open, or the model isn't available. The toggle unlocks only when everything is ready. Close the panel and the app stays in the menu bar.
  Why now: Screen permission only works for a real `.app` bundle, so it has to exist before we can capture WhatsApp. It's also the second unfamiliar piece: ad hoc signing and the permission prompt.
  PRD ref: `prd.md > The Core Journey` (steps 1–4), `prd.md > Control Panel and Toggle`, `prd.md > States and Boundaries`
  Spec ref: `spec.md > App Shell and Menu Bar`, `spec.md > Control Panel`, `spec.md > Permissions & Readiness`, `spec.md > Where It Runs and How Someone Tries It`, `spec.md > Look and Feel`
  Build: `StickerTranslatorApp.swift` (MenuBarExtra + panel window), `AppState.swift`, `ControlPanelView.swift`, `Readiness.swift`, `Resources/Info.plist` (LSUIElement), `scripts/build-app.sh` and `scripts/run.sh`, and a first `README.md` covering how to run it and grant permission.
  Verify (mechanical): `./scripts/build-app.sh` produces a signed bundle (`codesign -v` passes, plist has LSUIElement); the app launches and its process keeps running; readiness logic reports the right status with WhatsApp running and not running.
  Learner check: Run `./scripts/run.sh`. With WhatsApp closed, the panel should say so; grant screen permission if asked, open WhatsApp, and the status should turn green and the toggle unlock. Close the panel and reopen it from the menu bar.
  Commit: `Add menu-bar app shell, control panel, and readiness checks`

- [x] **3. Turn on the toggle, and Spanish stickers in WhatsApp get a tooltip beside them**
  Becomes usable: The core journey works live. With the toggle on, the app snapshots the WhatsApp window about 3 times per second. Each Spanish block gets a dark tooltip next to it showing "Translating… please wait a moment," then LITERAL and MEANING. English and text-free stickers get nothing. Turning the toggle off removes everything.
  Why now: This is the "oh, that's cool" moment from the scope, and it's built on the two risky pieces already proven. Coordinate mapping (Vision's box → window → screen) is where things are most likely to go subtly wrong, so we want your eyes on it right away.
  PRD ref: `prd.md > The Core Journey` (steps 5–7, 10), `prd.md > Automatic Detection`, `prd.md > Translation Tooltip`, `prd.md > Control Panel and Toggle`
  Spec ref: `spec.md > Window Watcher`, `spec.md > Translation Cache`, `spec.md > Tooltip Overlay`, `spec.md > Look and Feel`, `spec.md > The Core Journey Through the System`
  Build: `WindowWatcher.swift` (ScreenCaptureKit, WhatsApp window only), `TranslationCache.swift`, `OverlayController.swift` (coordinate mapping, right-side placement with left fallback), `TooltipView.swift` (loading and done states, styled per Look and Feel); wire the toggle to start and stop the pipeline in `AppState`.
  Verify (mechanical): Build passes; with WhatsApp showing a test sticker, I capture a screenshot of the screen and confirm a tooltip panel exists beside the text and that its contents match the `--check` output for that image; toggle off → no tooltip windows remain.
  Learner check: Open a chat containing a Spanish sticker (send yourself one of the samples if needed), turn on the toggle, and watch: "Translating…" should appear next to the sticker, then the translation. Does the placement and look match what you pictured?
  Commit: `Show live translation tooltips beside Spanish stickers in WhatsApp`

- [ ] **4. Tooltips follow scrolling, close with ✕, and recover from errors**
  Becomes usable: Scroll the chat and tooltips move with their stickers, hide when the sticker leaves the view, and come back instantly when it returns. ✕ closes a tooltip for the rest of the session. A failed translation shows "Couldn't translate this sticker" with ↻ Retry. When literal and meaning are the same, only one line shows. Works with Wi-Fi off.
  Why now: These behaviors polish the core loop and depend on slice 3's re-scan loop and cache. They're the rest of `What We're Building`.
  PRD ref: `prd.md > Scroll Tracking`, `prd.md > Translation Tooltip`, `prd.md > States and Boundaries`, `prd.md > Privacy`, `prd.md > Open Questions`
  Spec ref: `spec.md > Tooltip Overlay`, `spec.md > Translation Cache`, `spec.md > Important Failure Modes`, `spec.md > Decisions and Open Issues`
  Build: Hide/show panels by presence in each frame; the ✕ button marks a block closed in the cache; error state plus Retry in `TooltipView`; collapse literal = meaning into one line; clickable-only-on-controls, non-activating panels; finish `README.md` with the privacy note and known limitations.
  Verify (mechanical): Build passes; a forced translator failure (debug flag) shows the error and Retry recovers it; I simulate scroll by scrolling WhatsApp and confirm through screenshots that the tooltip moves and hides; closing marks the cache entry closed and it doesn't return; `--check` still succeeds with networking off.
  Learner check: Scroll up and down past a translated sticker, close one tooltip with ✕ and scroll away and back, then turn off Wi-Fi and receive a new sticker. Everything should keep working.
  Commit: `Track scrolling, add close and retry, finish README`

## Hands-on Checkpoints

- [ ] Early usable behavior explored — after slice 1 (is the meaning good enough?) and after slice 3 (first live tooltip in WhatsApp)
- [ ] Final kick-the-tires exploration and feedback completed

## Final Review

- [ ] Final review complete — feedback resolved and learner confirms ready to ship

## Code Tour and App Map

- [ ] Learning activity complete — guided route, focused alternative, prior practice connected, or brief recap
- [ ] Optional edit and transfer reflection addressed — offered/declined/already covered/not applicable as appropriate
- [ ] `devpost/app-map.html` generated from finished code, checked, and shown, including a project-grounded practice to reuse

Activity and evidence: 
Route and stops: 
Edit outcome: 
Reflection: 
Activity mode: 

## Revisions

- Translator uses plain two-line output instead of `@Generable`, with permissive guardrails — the `@Generable` macro plugin only ships with full Xcode (this Mac has Command Line Tools only), and the default guardrails rejected most slang, even "ya me voy a dormir".
- Added a built-in Slang Glossary that feeds notes into the prompt (learner's choice) — the on-device model alone explained Mexican slang confidently wrongly ("qué oso" → "How cool!", "aguas" → "I'm thirsty").
- `build-app.sh` signs with a self-signed local "Sticker Translator Dev" identity (created once by the learner via `scripts/make-dev-cert.sh`), falling back to ad hoc — ad hoc rebuilds lost the screen permission every time, as the spec's failure mode predicted.
- A glossary match now counts as Spanish unless the text is clearly English (was: Spanish confidence ≥ 0.15), glossary entries can be flagged `playful`, and WhatsApp's time/✓✓ labels are dropped before grouping — at the early checkpoint, deliberately misspelled stickers ("ola wen dia", 3% Spanish) were filtered out, and timestamps merged into sticker text made tooltips retranslate and jump.
