---
doc: spec
status: approved
---

# Sticker Translator — Technical Spec

## How This Works, In Plain Language
Sticker Translator is a small native Mac app written in Swift. It uses only frameworks that come with macOS, so nothing is downloaded and nothing leaves the Mac.

It has five pieces:
1. **Control panel:** a small window with the "Always translate images" toggle and a status line. It hides to the menu bar.
2. **Window watcher (ScreenCaptureKit):** while the toggle is on, it takes a snapshot of *only* the WhatsApp Desktop window a few times per second.
3. **Text finder (Vision):** reads the text in each snapshot, groups nearby lines into one "sticker," and checks whether the text is Spanish.
4. **Translator (Foundation Models, Apple's on-device AI model):** for each new Spanish sticker, it looks up any known slang in a built-in **slang glossary**, then writes a literal translation and a short explanation of the meaning. Results are saved by sticker text, so each sticker is translated only once.
5. **Tooltip overlay:** small dark floating windows placed next to each sticker on screen. On every snapshot they move to where the text is now and hide when it's gone.

**Why this shape:** "re-scan, don't track." The app doesn't follow each sticker as it moves. It looks again a few times per second, and each tooltip goes wherever its text is now. That keeps it simple and survives scrolling, at the cost of tooltips trailing a fraction of a second behind fast scrolls.

## The Core Journey Through the System
PRD ref: `prd.md > The Core Journey`.

1. The user runs the app → the **Control Panel** opens and asks **Permissions & Readiness** whether screen permission is granted, whether WhatsApp is running, and whether the on-device model is available → the status line shows whatever is missing.
2. The user turns on the toggle → the **Window Watcher** finds WhatsApp's window and starts taking snapshots of it (about 3 per second).
3. The control panel is closed → the app keeps running in the **menu bar**.
4. Each snapshot → the **Text Finder** reads all text along with its position, groups it into blocks, and keeps only blocks the **Language Filter** identifies as Spanish.
5. For each Spanish block → the **Translation Cache** is checked:
   - **New** → mark it "translating" → the **Tooltip Overlay** shows "Translating… please wait a moment" → the **Translator** asks the on-device model → the cache stores the literal translation and meaning (or the error).
   - **Already known** → reuse the stored result.
   - **Closed by the user** → skip.
6. The **Tooltip Overlay** converts each block's position into screen coordinates and places or moves its tooltip beside it. Tooltips whose text is no longer in the snapshot are hidden.
7. ✕ → the block is marked closed in the cache and its tooltip is removed. **Retry** → the cached error is cleared and the block is translated again.
8. Toggle off → snapshots stop and all tooltips are removed.

## Stack
- **Swift 6 / SwiftUI + AppKit**, macOS 26. Native, so overlays, the menu bar, and screen capture are first-class. The learner is comfortable with this.
- **ScreenCaptureKit**, to capture one window. https://developer.apple.com/documentation/screencapturekit
- **Vision** (`VNRecognizeTextRequest` / `RecognizeTextRequest`, `es-ES`), for on-device text recognition. https://developer.apple.com/documentation/vision/recognizing-text-in-images
- **NaturalLanguage** (`NLLanguageRecognizer`), to check whether the text is Spanish. https://developer.apple.com/documentation/naturallanguage/nllanguagerecognizer
- **Foundation Models** (`SystemLanguageModel` with `.permissiveContentTransformations` guardrails, `LanguageModelSession`, plain two-line `LITERAL:` / `MEANING:` output), Apple's on-device model, for translation and meaning. `@Generable` isn't used: its macro plugin ships only with full Xcode, and this Mac has Command Line Tools only. https://developer.apple.com/documentation/foundationmodels
- **Swift Package Manager**, plus a small script that wraps the build into a `.app` bundle (needed for the menu bar and screen permission).

Verified on the learner's Mac (2026-10-02): `SystemLanguageModel.default.availability` = **available**; Vision supports **es-ES** but not Hindi. **Checked in build step 1 (2026-10-05):** on its own, the model gets Mexican slang meanings confidently wrong (for example "qué oso" → "How cool!"), and the default guardrails block most slang. With a short glossary note in the prompt, its meanings are correct. Hence the **Slang Glossary** component.

**Accepted tradeoff:** Apple's model is small (about 3B parameters), so explanations may be shallower than a cloud model's. The learner chose this in exchange for privacy and no downloads.

## Where It Runs and How Someone Tries It
- **Runs:** locally on the learner's MacBook Air M4 (macOS 26.3, Apple Intelligence on), with WhatsApp Desktop open.
- **Build and run:** `./scripts/run.sh` builds the package, assembles `build/StickerTranslator.app`, signs it ad hoc, and opens it.
- **First run:** grant **Screen & System Audio Recording** permission to Sticker Translator in System Settings → Privacy & Security, then relaunch.
- **Demo recording:** WhatsApp Desktop on one side with a staged, funny Spanish-sticker exchange in English text, and the control panel on the other. Turn on the toggle and the panel hides. A sticker arrives, "Translating…" appears, then the literal translation and meaning. Scroll to show the tooltip following and hiding. Close one with ✕. Optionally turn off Wi-Fi to show it still works.
- **Submission:** demo video + public GitHub repo. **No deployment and no downloadable app:** distributing a signed, notarized app needs a paid Apple Developer account (learner agreed).
- **Public repo:** https://github.com/Avhijit-Nair/WhatsApp-Sticker-Translator
- **Demo video:** https://youtu.be/YijCi-7z2PY

## Look and Feel
From `prd.md > Look and Feel`, `scope.md > Inspiration & Identity`.
- **Tooltip:**
  - **Shape and color:** a near-black panel (`#1B1F24` at about 92% opacity) with 10pt rounded corners and a subtle shadow. Maximum width about 260pt.
  - **Text:** system font (SF Pro). Small all-caps section labels "LITERAL" and "MEANING" in soft teal (`#9FE3D6`, 10–11pt bold). Body text in white, 13pt.
  - **Controls:** a gray ✕ in the top-right corner. The error state shows the message in soft red (`#FFB4B4`) and a small "↻ Retry" button.
- **Placement:** to the right of the sticker's text block, vertically aligned with it. If there's no room on the right, it goes on the left. It never covers the sticker.
- **Control panel:** a native SwiftUI form, small and plain. Toggle, "Language: Spanish → English," and a status line with a colored dot (orange = something missing, green = running).
- **Tone of copy:** short and friendly, for example "Translating… please wait a moment."

## Components

### App Shell and Menu Bar
Starts the app, owns `AppState`, and provides a `MenuBarExtra` (open panel / quit). Runs as a menu-bar app (`LSUIElement`), so it has no Dock icon and doesn't get in WhatsApp's way.
PRD ref: `prd.md > Control Panel and Toggle`, `prd.md > Screens and Layout`.

### Control Panel
A SwiftUI window with the toggle, the language label, and the status line. Hiding it doesn't stop translation.
PRD ref: `prd.md > Control Panel and Toggle`, `prd.md > States and Boundaries`.

### Permissions & Readiness
Checks three things and reports the first problem to the status line:
- Screen permission: `CGPreflightScreenCaptureAccess`; ask with `CGRequestScreenCaptureAccess`.
- WhatsApp running: `NSRunningApplication`, bundle ID `net.whatsapp.WhatsApp` (verified on this Mac).
- Model availability: `SystemLanguageModel.default.availability`.

The toggle stays disabled until all three pass. It re-checks when the panel opens and every few seconds while there's a problem.
PRD ref: `prd.md > States and Boundaries` (permission missing, WhatsApp not open).

### Window Watcher
Uses ScreenCaptureKit to find WhatsApp's main on-screen window and capture only that window (`SCContentFilter(desktopIndependentWindow:)`), so our own tooltips are never in the snapshot. Delivers about 3 frames per second with the window's current screen frame. Stops when the toggle is off.
PRD ref: `prd.md > Automatic Detection`, `prd.md > Scroll Tracking`.

### Text Finder
Runs Vision text recognition (accurate level, `es-ES` + `en-US`) on each frame. Groups lines whose boxes are close together into **blocks**: one block ≈ one sticker. Each block has its joined text and its bounding box.
PRD ref: `prd.md > Automatic Detection`.

### Language Filter
Keeps a block only if `NLLanguageRecognizer` identifies Spanish as the dominant language with reasonable confidence (starting threshold of 0.6, to be tuned) and the text has at least 2 letters. Blocks that are English or have no text are dropped, so they get no tooltip.
PRD ref: `prd.md > Automatic Detection`.

### Translator
A `LanguageModelSession` (permissive guardrails, low temperature) with instructions roughly like this: "You're a friendly bilingual Mexican Spanish tutor. Given a sticker's text and glossary notes, reply in two lines: LITERAL (word-for-word English) and MEANING (one sentence on what it really means and its tone)." The reply is parsed into `StickerTranslation { literal, meaning }`. Runs one request at a time. Errors (refusal, guardrail, timeout) become a failed result.
PRD ref: `prd.md > Translation Tooltip`, `prd.md > Privacy`.

### Slang Glossary
A curated JSON list (`slang-glossary.json`, about 60–100 common Mexican slang phrases), bundled with the app. Each entry has the phrase, any spelling variants, and a short note on what it really means. Before each translation, sticker text is normalized (lowercased, accents and punctuation stripped) and matched against the phrases on whole words. Matching notes go into the prompt, and the model is told to trust them. A glossary match also counts as evidence that the text is Spanish (short slang such as "qué oso" can fool the language check). Phrases not in the glossary fall back to the model's own knowledge, which may be wrong. Anyone can add entries by editing the JSON.
PRD ref: `prd.md > Translation Tooltip` (meaning line).

### Translation Cache
An in-memory dictionary keyed by **normalized block text** (lowercased, whitespace collapsed). Each entry is `translating | done(literal, meaning) | failed(message) | closed`. This is what makes tooltips reappear immediately after scrolling and what keeps closed tooltips closed.
PRD ref: `prd.md > Translation Tooltip`, `prd.md > Scroll Tracking`.

### Tooltip Overlay
For each visible Spanish block, it keeps one small borderless, non-activating floating `NSPanel` hosting a SwiftUI `TooltipView`. Each frame, it converts the block's box from Vision's normalized coordinates to the WhatsApp window's frame and then to screen coordinates (flipping the Y axis). It then moves the panel beside the block. A block that's missing from the frame gets its panel hidden; a block that comes back gets it shown again. The panels accept clicks only on ✕ and Retry, and never take focus from WhatsApp.
PRD ref: `prd.md > Translation Tooltip`, `prd.md > Scroll Tracking`, `prd.md > Look and Feel`.

### Dev Check Tool
A command-line mode (`--check <image>`) that runs Text Finder → Language Filter → Translator on an image file and prints the result. It's used to verify the pipeline and test explanation quality without WhatsApp. It's a dev tool only and isn't shown in the demo.
PRD ref: supports verification of `prd.md > Translation Tooltip`.

## Data Model
All data is in memory. **Nothing is saved to disk, and nothing leaves the Mac.**

| Data | Lives in | Updated when | After quitting and relaunching |
|---|---|---|---|
| Toggle on/off | `AppState` | user flips it | starts **off** |
| Readiness status | `AppState` | re-check | re-checked |
| Latest frame + WhatsApp window frame | Window Watcher | ~3×/sec | gone |
| Blocks `{text, box}` in the current frame | Text Finder output | each frame | gone |
| Slang glossary `phrase → note` | bundled JSON, read-only | edited by hand | unchanged |
| Cache `text → translating/done/failed/closed` | Translation Cache | translation finishes, ✕, Retry | **gone** (closed tooltips can come back; deferred in `prd.md > Deferred From the POC`) |
| Tooltip panels `text → NSPanel` | Tooltip Overlay | each frame | gone |

## File Structure
```
hackathon/
├── Package.swift                         # SwiftPM: one executable target, macOS 26
├── Sources/StickerTranslator/
│   ├── StickerTranslatorApp.swift        # App Shell: @main, MenuBarExtra, panel window
│   ├── AppState.swift                    # toggle, status, starts/stops the pipeline
│   ├── ControlPanelView.swift            # Control Panel UI
│   ├── Readiness.swift                   # Permissions & Readiness checks
│   ├── Pipeline/
│   │   ├── WindowWatcher.swift           # ScreenCaptureKit capture of WhatsApp window
│   │   ├── TextFinder.swift              # Vision OCR + grouping into blocks
│   │   ├── LanguageFilter.swift          # NaturalLanguage Spanish check
│   │   ├── Translator.swift              # Foundation Models session + StickerTranslation
│   │   ├── SlangGlossary.swift           # loads + matches the glossary
│   │   └── slang-glossary.json           # curated Mexican slang notes (bundled resource)
│   │   └── TranslationCache.swift        # text → state
│   ├── Overlay/
│   │   ├── OverlayController.swift       # coordinate mapping, panel placement/hiding
│   │   └── TooltipView.swift             # dark tooltip: loading / done / error + ✕ / Retry
│   └── DevCheck.swift                    # --check <image> command-line mode
├── Resources/
│   └── Info.plist                        # bundle ID, LSUIElement, usage text
├── scripts/
│   ├── build-app.sh                      # swift build → build/StickerTranslator.app, ad hoc sign
│   └── run.sh                            # build-app + open
├── samples/                              # test sticker images (illustrative, public-safe)
├── README.md                             # what it is, how to run, permissions, privacy
├── .gitignore                            # also ignores build/ and .build/
└── devpost/                              # planning docs
```

## External Services and Dependencies
**None.** There are no network APIs, no keys, and no cost. All frameworks ship with macOS 26. Requirements:
- macOS 26 on Apple silicon, with **Apple Intelligence turned on** (for Foundation Models).
- Screen recording permission granted to the app.
- WhatsApp Desktop for Mac installed.

## Important Failure Modes
- **Screen permission is lost after rebuilding** (ad hoc signatures change, so macOS may treat each build as a new app) → the status line shows "permission required." Re-grant it in System Settings. If this becomes annoying, sign with a free Apple Development certificate from Xcode for a stable identity.
- **The model refuses, errors, or is slow** → the tooltip shows "Couldn't translate this sticker" with Retry (`prd.md > States and Boundaries`). "Translating…" stays visible while it works.
- **Text recognition misreads stylized sticker fonts, or the language check gets short text wrong** (for example, "jaja") → the tooltip may not appear, or may show an error. Tune the grouping and threshold using the Dev Check Tool and `samples/`.
- **A Spanish text message (not a sticker) is on screen** → it would get a tooltip too. This is a known limitation; the demo uses English text messages.

## What Was Simplified and Why
- **Any Spanish text on screen is treated as a sticker**, instead of first detecting image regions. The learner's demo keeps text messages in English. The fuller version would check macOS's accessibility information about WhatsApp's layout, or detect image regions, so that only text inside images counts. That's an optional stretch if time allows.
- **Re-scan a few times per second** instead of tracking each sticker as it moves. It's simpler and handles scrolling naturally. The fuller version would track motion between frames, for smoother tooltips.
- **One tooltip state per unique text** instead of per sticker instance. Identical stickers share a tooltip state. The fuller version would identify each sticker by its position in the chat.
- **In-memory only:** nothing persists between launches.
- **Local run + video**, with no distributed app (it would need a paid Apple Developer account and notarization).

## Decisions and Open Issues
**Learner decisions:**
- **Native Swift Mac app with Apple's on-device frameworks:** comfortable with Swift. Privacy and no downloads were worth shallower explanations.
- **Demo has Spanish only in stickers; text messages in English:** accepted that Spanish text messages would also get tooltips.
- **Re-scan approach for scrolling:** accepted that tooltips trail slightly behind fast scrolls.
- **Local run + demo video, no deployment or download.**

- **Built-in slang glossary (build step 1):** the on-device model alone got slang meanings wrong. The learner chose a curated, on-device glossary over a bigger downloaded model or staging the demo around phrases it happens to get right. Unknown slang may still be explained wrongly.

**Implementation details derived from those decisions (agent):** about 3 frames per second, cache keyed by normalized text, a separate floating panel per tooltip, the 0.6 language-confidence starting threshold, the SwiftPM + bundling script, and the `--check` dev mode.

**Learner uncertainty discussed:** how the app tells sticker text from message text. We discussed that text recognition only sees "text." **Resolved** for the proof of concept by staging the demo (Spanish only in stickers) and recording the limitation. An accessibility-based check is an optional stretch.

**Checked early in the build (step 1):** explanation quality. It was weak without help, so we use the glossary (above).

**Verify early:** whether ScreenCaptureKit captures it as a normal window; how well Vision reads stylized sticker fonts.

**Carried from `prd.md > Open Questions`:**
- When literal = meaning, show only one line: decide in the build.
- The toggle starts off after a restart (as in the PRD assumption).
