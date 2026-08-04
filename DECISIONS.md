# Decisions

## Product
- App: AI baby-photo studio — user uploads a baby photo, picks a theme, gets an AI-generated studio portrait back.
- Name: **Newborn Studio: AI Baby Photos** (kept from the existing App Store Connect record).
- Bundle ID: **com.NewbornStudio** (kept — existing ASC app, "Ready For Distribution" 1.0.1).
- Rebuild from scratch: previous codebase not reused. New native Swift/UIKit implementation, new design. Existing App Store Connect and Firebase project registrations are reused.

## Tech stack
- **Swift + UIKit** (no SwiftUI), targeting **iOS 15+**.
- Backend: **Firebase** — reusing the existing `newborn-studio` Firebase project (functions + hosting scaffolded fresh in this repo, not copied from the old `~/newbornfunc` / `~/newbornPublic` folders).
- AI image generation: **Wiro.ai**, model `google/nano-banana` (Gemini 2.5 Flash Image). Called server-side only (Cloud Functions) — the API secret must never ship in the client binary.
- Design: sourced from Claude Design project **"Newborn Studio App Design"** (`9c003995-88f6-4dd1-bd8a-ac345052d187`), file `Newborn Studio.dc.html` — saved locally at `Design/Newborn Studio.dc.html` (10 hi-fi screens: Onboarding x3, Home/Theme Gallery, Photo Upload, AI Generation/Loading, Result/Preview, Photo Editor, Milestone Tracker, Paywall/Subscription, Coin Package, Profile/Settings).
- Design tokens extracted from the mockups:
  - Fonts: **Quicksand** (headings, 600-700 weight), **Nunito** (body, 400-800 weight), Material Symbols Rounded (icons).
  - Accent: pink/rose gradient `#F4A6B3 → #E5738D` (primary CTA, active states).
  - Backgrounds: warm cream `#FFFBF7`, `#F6EFEA`, `#E9E2DA`; soft gradients per-screen (pink/lavender/mint) for onboarding.
  - Text: dark plum `#463A3F`/`#4A3F44` (primary), muted mauve `#A38C90`/`#8C7D80` (secondary).
  - Semantic: success green `#4FA07C` on `#E0F3EA`; coin/gold `#E8A93C` on `#FFF3D9`; purple accent `#7A63C4` on `#EDE7FB`.
  - Shape language: large corner radii (22-44px), pill-shaped buttons (100px radius), soft colored drop shadows matching each card's accent.
  - Paywall mockup shows only Weekly/Yearly plan cards — the Monthly ($14.99) tier will be added as a third card in the same visual style since the design didn't include it.
- **Photo Editor screen (mockup #6) is cut** — not building it, per user decision.
- **Milestone Tracker is private-only** — never shared with other users, no social/discover layer anywhere in the app.

## Monetization (RevenueCat + credits)
Existing ASC products for `com.NewbornStudio` (pulled via `ascelerate sub/iap pricing show`, prices below are USA base):
- Subscription tiers (group "Newborn Studio Premium Group"):
  - Weekly `com.newborn.weekly` — **$4.99/week**, grants 10 credits/week.
  - Monthly `com.newborn.monthly` — **$14.99/month**, grants 50 credits/month. **Does not exist in ASC yet — create in Phase 7/9.**
  - Yearly `com.newborn.yearly` — **$49.99/year**, grants 500 credits/year.
- Consumable credit packs (all `Approved` state already):
  - Small `com.newborn.small` — **$3.99** — 5 credits
  - Limited `com.newborn.limited` — **$6.99** — 25 credits
  - Medium `com.newborn.medium` — **$9.99** — 15 credits
  - Big `com.newborn.big` — **$19.99** — 50 credits
- Credit-to-cost unit economics not yet computed against Wiro's per-call cost — do before finalizing whether these prices hold (playbook cost-section rule: `credit_cost = ceil(cost_USD / 0.01)`).
- ASC API key in use: keyId `YC2YC44RMZ`, issuerId `1aba5c58-f408-4036-b737-5a6c226d821e` (`~/.ascelerate/config.json`).

## Xcode project tooling
- Project generated with **XcodeGen** from `project.yml` (the Swift equivalent of `flutter create` for automation) — no manual Xcode GUI project setup. Regenerate with `xcodegen generate` after any `project.yml` change; don't hand-edit the `.xcodeproj`.
- XcodeGen's `info:` target key regenerates/overwrites Info.plist from its own template — do NOT use it with a hand-authored Info.plist. Instead reference the file as-is via `settings.base.INFOPLIST_FILE` + `GENERATE_INFOPLIST_FILE: NO`.
- **Quicksand and Nunito ship only as variable fonts** (single `wght` axis) in the current Google Fonts repo, no static per-weight files. `Theme.Font` dials in the exact weight at runtime via the CoreText `kCTFontVariationAttribute` (axis tag `wght` = `0x77676874`) rather than loading separate `-Bold`/`-SemiBold` files.
- App icon asset uses the single-size 1024x1024 universal `AppIcon.appiconset` format (Xcode auto-generates all other sizes) — the source PNG must be full-bleed with no alpha, no pre-baked rounded corners/shadow (iOS applies its own mask).

## Secrets
- `WIRO_API_KEY` / `WIRO_API_SECRET` stored in `.env` (gitignored), never in Claude memory or committed history.
