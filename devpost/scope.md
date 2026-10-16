---
doc: scope
status: approved
---

# WhatsApp Image Translator (working title)

An always-on Mac overlay that spots Spanish text in images and stickers in WhatsApp Desktop and labels each one with a literal translation and what it actually means, entirely on-device.

## The Unique Kernel
**Zero steps.** You flip one toggle, "always translate images," and every Spanish sticker or meme in the chat gets a label with the literal translation *and* the meaning (slang, tone, the joke). You never stop to ask. Circle to Search / Google Lens can translate an image, but only when you stop and ask each time. Text translation is already solved (for example, Pixel's built-in translation); images are the gap.

## Who It's For
The learner, and anyone in a cross-language relationship or friendship, chatting on WhatsApp with someone whose stickers and memes are in another language. Today they either guess, ask, or leave the conversation to run each image through Lens.

## The Core Loop
Turn on "always translate images" once. Keep chatting in WhatsApp Desktop. When a Spanish sticker or image appears, a small label shows up next to it, on a transparent layer over the app, with:
- the literal translation
- a short explanation of what it really means

Nothing to click. It just keeps working as the conversation goes on.

## Inspiration & Identity
- **Cluely-style transparent overlay:** it sits on top of the app instead of being a separate tool.
- **A label next to the image,** not drawn over it. The original sticker stays visible.
- **Fun and personal:** the demo should be a funny exchange between the learner and their friend.

## Why This Matters to the Learner
A real, everyday annoyance: "some of the stickers are in Spanish and I don't have a tool that instantly translates" them when chatting with their Mexican friend. Hackathon goal: stand out to non-expert judges and win a share of the prize money. This idea is instantly understandable. It also touches their interest in running AI models locally on a device.

## What "Working" Looks Like
WhatsApp Desktop is open on the Mac and the toggle is on. A funny exchange plays out. She sends a Spanish sticker, and a moment later a label appears next to it with the translation and the slang explained, all without the learner touching anything.

**The "oh, that's cool" moment:** the label appears on its own and explains the *joke*, not just the words.

## The POC Boundary
- macOS only, WhatsApp Desktop only.
- An on/off toggle for "always translate images."
- Automatically finding Spanish text in images and stickers visible in the chat.
- Labels next to each image on a transparent always-on-top layer: literal translation + meaning.
- Spanish → English.
- **Fully on-device:** screenshots and chat content never leave the Mac. Privacy matters "even for this one."

## Later
- Android overlay on the learner's Pixel (Android allows drawing over other apps)
- Other messaging apps and other language pairs
- Better slang and cultural explanations, possibly a model customized for this (ties to the learner's model-compression interest)
- Translating text messages too (lower priority, since Pixel already does this)
- Growing the slang glossary from real chats: collect unknown phrases with the model's guess for review, never trusted automatically (raised during build step 1)

## Explicitly Cut
- **iPhone version:** iOS doesn't let apps draw on top of WhatsApp.
- **Cloud AI APIs:** they would send private chat screenshots off the device, which conflicts with the privacy requirement.
- **Redrawing the image with translated text:** the learner chose labels, which keep the original visible and are simpler.
- **Text-message translation:** already solved by built-in phone translation.

## Earlier Directions (set aside)
- **Graphene coatings evidence explorer:** set aside because the learner doesn't think customers would use it, and hard-tech framing is a poor fit for non-expert judges.
- **Automated model compression to on-device models:** a real pain point, but hard to show visually and too large for 2–4 hours.
- **Agent-friendly websites:** secondhand idea (from a reel).

## Notes for Later Phases
- The demo video will be public and show a real chat. Stage an exchange the friend is comfortable sharing.
- On-device explanation quality is the main risk. `4-spec` should check which local models fit on the learner's MacBook Air M4.
