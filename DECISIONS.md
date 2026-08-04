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

## Monetization (RevenueCat + credits)
- Subscription tiers:
  - Weekly: grants 10 credits/week. Price: **TBD**.
  - Monthly: **$14.99/mo**, grants 50 credits/month.
  - Yearly: grants 500 credits/year. Price: **TBD**.
- Consumable credit packs (one-time):
  - Small: 5 credits — price TBD
  - Medium: 15 credits — price TBD
  - Big: 50 credits — price TBD
  - Limited: 25 credits — price TBD
- Credit-to-cost unit economics not yet computed against Wiro's per-call cost — do before finalizing prices (playbook cost-section rule: `credit_cost = ceil(cost_USD / 0.01)`).

## Secrets
- `WIRO_API_KEY` / `WIRO_API_SECRET` stored in `.env` (gitignored), never in Claude memory or committed history.
