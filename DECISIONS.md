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
- Design: sourced from Claude Design (claude.ai/design) via the DesignSync tool — pending: user needs to confirm/share the correct design project (see PROGRESS.md open items).

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
