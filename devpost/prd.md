---
doc: prd
status: approved
---

# Sticker Translator — Product Requirements

A Mac app that runs quietly alongside WhatsApp Desktop and automatically labels Spanish stickers and images with an English translation and what they really mean, entirely on-device. It's for someone chatting with a person whose stickers come in another language.
Source: `scope.md > The Unique Kernel`, `scope.md > Who It's For`.

## The Core Journey
Source: `scope.md > The Core Loop`, `scope.md > What "Working" Looks Like`.

1. The user opens Sticker Translator. A small **control panel** window appears.
2. **First use:** if macOS screen permission hasn't been granted, the panel says permission is required and that the app can't work until then. If WhatsApp Desktop isn't open, the panel says so.
3. Once ready, the user turns on **"Always translate images."**
4. The control panel goes to the background, into the **menu bar**, so it doesn't get in WhatsApp's way.
5. The user keeps chatting in WhatsApp Desktop as normal.
6. When a sticker or image with **Spanish text** is visible in the chat, a **dark tooltip** appears next to it saying "Translating… please wait a moment."
7. The tooltip then shows the **literal translation** and the **meaning** (slang, tone, the joke).
8. As the user scrolls, each tooltip **moves with its sticker**. It disappears when the sticker leaves the visible chat area and reappears when it comes back.
9. The user can close any tooltip with its **✕**. A closed tooltip stays closed.
10. **Success:** in a staged, funny exchange, a Spanish sticker arrives and its tooltip explains the joke without the user touching anything.

## Screens and Layout

### Control Panel
A small window. Contents:
- **"Always translate images"** on/off toggle
- **Language:** Spanish → English (the only option in this proof of concept; see `Deferred From the POC`)
- **Status area:** shows when permission is missing or WhatsApp isn't open, otherwise shows that it's ready or running

When it's not in use, it lives in the macOS menu bar and can be reopened from there.

### Translation Tooltip (overlay)
A transparent, always-on-top layer over WhatsApp Desktop that draws one tooltip next to each Spanish sticker. There are no other surfaces.

## Look and Feel
- **Tooltip:** a dark or black floating tooltip, as in the scope mockup (`scope.html`), sitting *next to* the sticker and never covering it.
- **Tooltip content:** a "LITERAL" line and a "MEANING" line, plus a small ✕ in the corner.
- **Control panel:** small and unobtrusive. No specific style established; keep it simple and native-feeling (assumption).
- **Avoid:** anything that covers or redraws the sticker itself.

## Features and Behavior

### Control Panel and Toggle
- As a user, I want one toggle that makes translation always-on, so I never have to stop and ask.
  - [ ] Turning on "Always translate images" starts automatic translation of visible Spanish stickers.
  - [ ] Turning it off stops translation and removes all tooltips (assumption).
  - [ ] The control panel can be hidden to the menu bar and reopened from there.
  - [ ] The language shows Spanish → English.

### Automatic Detection
Source: `scope.md > The POC Boundary`.
- [ ] Stickers and images visible in the WhatsApp Desktop chat that contain **Spanish text** get a tooltip without the user doing anything.
- [ ] Stickers with **no text** or with **English text** get **no tooltip**.

### Translation Tooltip
- [ ] While working, the tooltip shows "Translating… please wait a moment."
- [ ] When finished, the tooltip shows the literal English translation and a short explanation of the meaning.
- [ ] The tooltip sits beside its sticker and doesn't cover it.
- [ ] The ✕ closes the tooltip. That tooltip doesn't come back during the session, even after scrolling away and back.

### Scroll Tracking
- [ ] When the chat scrolls, each tooltip moves with its sticker.
- [ ] When a sticker scrolls out of the visible chat area, its tooltip disappears. When the sticker scrolls back in, the tooltip reappears (unless it was closed).

### Privacy
Source: `scope.md > The POC Boundary`.
- [ ] Translation works with the Mac's network turned off, which shows that no screenshots or chat content leave the device.

## States and Boundaries
- **Permission missing:** the control panel says screen permission is required and that the app can't operate until it's granted. No tooltips appear.
- **WhatsApp Desktop not open:** the control panel says so. No tooltips appear (assumption: shown in the same status area as the permission message).
- **Toggle off:** no detection and no tooltips.
- **Translating:** the tooltip shows "Translating… please wait a moment."
- **Translated:** the tooltip shows the literal translation and the meaning.
- **Translation failed / unreadable text:** the tooltip shows an error message with a **retry** button. Retry tries that sticker again.
- **No text / English text:** no tooltip.
- **Closed by user:** stays closed for that sticker.
- **Off-screen:** tooltip hidden; reappears when the sticker is visible again.

## Product Decisions
- **Name: Sticker Translator.**
- **Control panel plus menu bar:** a small panel for setup, then it hides "so that it doesn't interrupt WhatsApp."
- **Tooltip next to the sticker, not drawn over it:** keeps the original visible (from scope).
- **Tooltips follow scrolling:** the learner chose the harder version for the magical feel.
- **Closed stays closed:** prevents dismissed tooltips from coming back.
- **Skip stickers without text or with English text:** "just leave it."
- **A loading message instead of silence:** the user knows something is happening.
- **Error plus retry instead of disappearing.**
- **Spanish only for now:** Hindi was considered and deferred because on-device Hindi script reading is riskier.
- **Fully on-device:** privacy matters "even for this one" (from scope).

## What We're Building
- Control panel with the toggle, Spanish → English, and status messages; can hide to the menu bar
- Automatic detection of Spanish text in visible WhatsApp Desktop stickers and images
- Dark tooltips beside each one: loading → literal + meaning, or error + retry
- Tooltips that follow scrolling, hide when off-screen, and stay closed when dismissed
- Everything on-device

## Deferred From the POC
- **Hindi (and other source languages):** on-device Hindi script reading is less reliable; the selector would come back with it.
- **Remembering closed tooltips across app restarts:** closed-stays-closed applies only to the current session.
- **Android / Pixel overlay:** a separate platform (from scope).

## Possible Later Enhancements
- Other messaging apps.
- Better slang explanations from a model customized for this (ties to the learner's model-compression interest).
- Translating text messages too.
- Catching the stickers it sometimes misses (small or heavily stylized lettering), raised at final review and deferred to V2.
- Growing the slang glossary from stickers it hasn't seen: suggestions reviewed before they become trusted (deferred in build step 1; auto-adding would lock in the model's wrong guesses).

## Non-Goals
- **iPhone:** iOS doesn't allow overlays on other apps.
- **Cloud AI:** private screenshots would leave the device.
- **Redrawing the sticker with translated text:** tooltips keep the original visible.
- **Translating plain text messages:** phones already do this.

## Open Questions
- **When literal and meaning are the same** (for example, plain non-slang text), show both lines or only one? Can wait for the build.
- **Does the toggle stay on after the app restarts?** Assumption: it starts off. Can wait.
- **On-device explanation quality:** is a local model good enough to explain slang? This is a `4-spec` question to check early.
