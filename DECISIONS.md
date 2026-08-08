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
`com.NewbornStudio`'s products (old app) are the reference — same 7 product IDs re-created under `com.BabyCollages` (new app, "Newborn Moments") 2026-08-08 via `ascelerate`, mirroring the old app's prices/credit grants (which still match `functions/helpers/purchaseGrants.js`, the real source of truth for grant amounts):
- Subscription group "Newborn Moments Premium" (group level 1 for all three — duration variants of the same access, not feature tiers):
  - Weekly `com.babycollages.weekly` — **$4.99/week** target price, grants 10 credits/week.
  - Monthly `com.babycollages.monthly` — **$14.99/month** target price, grants 50 credits/month.
  - Yearly `com.babycollages.yearly` — **$49.99/year** target price, grants 500 credits/year.
  - **Created + en-GB localized (name/description) via API, but pricing is NOT set yet** — `ascelerate sub pricing set` 409s for every territory on this app (same known gate hit on the old app's `com.newborn.monthly`, see the old note this replaced). Root cause still unconfirmed; workaround is the ASC web UI (Distribution → the subscription → Availability, enter $4.99/$14.99/$49.99 in USA, let Apple auto-equalize the rest). **Human gate — needs doing before these can be submitted.**
- Consumable credit packs — created, en-GB localized, **and priced successfully via the API** (no gate hit for consumables):
  - Small `com.babycollages.small` — **$3.99** — 5 credits
  - Limited `com.babycollages.limited` — **$6.99** — 25 credits
  - Medium `com.babycollages.medium` — **$9.99** — 15 credits
  - Big `com.babycollages.big` — **$19.99** — 50 credits
- Credit-to-cost unit economics not yet computed against Wiro's per-call cost — do before finalizing whether these prices hold (playbook cost-section rule: `credit_cost = ceil(cost_USD / 0.01)`).
- **RevenueCat wiring — done 2026-08-09.** All 7 `com.babycollages.*` products created under app `app68c2b2ac6d` (RevenueCat v2 API, `sk_...` secret key from `.env`), each attached to the `newborn` entitlement (`entl04f774091a`) and to its matching package in the shared `newborn` offering (`ofrngc9d4f47816`) — weekly/monthly/yearly → `$rc_weekly`/`$rc_monthly`/`$rc_annual`, small/limited/medium/big → same-named custom packages. Verified via the API (GET each package's/entitlement's products) rather than assumed. **Never touch `is_current` on this offering** — see [[revenuecat-shared-project-is-current-flag]].
  - Still open: real purchase flow untested (no sandbox Apple ID / physical device in this environment) — only the RevenueCat-side wiring is verified, not an actual StoreKit sandbox transaction.
  - Also still open: localizing IAP/subscription name+description into the other 32 languages (only en-GB done so far) — ask before doing all of it (same shape as the earlier ASC-metadata pass).
- ASC API key in use: keyId `YC2YC44RMZ`, issuerId `1aba5c58-f408-4036-b737-5a6c226d821e` (`~/.ascelerate/config.json`). `ascelerate` alias `newborn` → `com.BabyCollages`.

## Xcode project tooling
- Project generated with **XcodeGen** from `project.yml` (the Swift equivalent of `flutter create` for automation) — no manual Xcode GUI project setup. Regenerate with `xcodegen generate` after any `project.yml` change; don't hand-edit the `.xcodeproj`.
- XcodeGen's `info:` target key regenerates/overwrites Info.plist from its own template — do NOT use it with a hand-authored Info.plist. Instead reference the file as-is via `settings.base.INFOPLIST_FILE` + `GENERATE_INFOPLIST_FILE: NO`.
- **Quicksand and Nunito ship only as variable fonts** (single `wght` axis) in the current Google Fonts repo, no static per-weight files. `Theme.Font` dials in the exact weight at runtime via the CoreText `kCTFontVariationAttribute` (axis tag `wght` = `0x77676874`) rather than loading separate `-Bold`/`-SemiBold` files.
- App icon asset uses the single-size 1024x1024 universal `AppIcon.appiconset` format (Xcode auto-generates all other sizes) — the source PNG must be full-bleed with no alpha, no pre-baked rounded corners/shadow (iOS applies its own mask).

## Theme catalog (content planning — not wired into the app yet)
- **20 categories × 15 styles = 300 total**, defined in `Design/Content/theme_catalog.json`: Newborn Classics, Fantasy & Fairytale, Space & Astronaut, Animals & Safari, Royalty & Kingdoms, Professions, Seasonal (Spring/Winter/Halloween/Summer — 4 separate categories), Ocean & Under the Sea, Superheroes, Storybook & Fairytale Characters, Sports, Vintage & Retro, Nature & Garden, Cultural & Traditional Dress, Food & Bakery, Music & Arts, Pets & Companions.
- Each style has a short **descriptor** (not a full prompt) + each category has a **mood**. The actual Wiro prompt is built from a fixed formula (descriptor + mood + non-negotiable constraints: preserve the baby's real face/likeness, no watermark, safe content) — see `Design/Content/PROMPT_TEMPLATE.md` for the exact formula and worked examples. Chosen over hand-writing 300 full prompts so the safety/quality constraints can't drift per-style.
- **Preview images generated and wired (done, live).** One consistent base reference photo (`Design/Generated/base_sample_baby.png`, a neutral text-to-image newborn portrait) is fed as `inputImage` to every style's stored prompt via Wiro image-to-image, so every theme card shows *the same baby* transformed into that theme — matches the product's actual promise. Each result is resized to a 640px-max JPEG (quality 87, ~25-35KB each) to keep the grid fast, uploaded to Storage at `ai_models/{styleId}/preview.jpg`, and its download URL written to `ai_models/{styleId}.previewImageUrl` via a temporary `seedThemePreviews` admin function (deployed, called 300 times from `Scripts/DesignAssets/generate_theme_previews.py`, then deleted — same one-off pattern as `seedThemes`).
- Batch result: **299/300 succeeded on the first pass, 1 failed and succeeded on immediate retry** — Wiro's content-safety classifier occasionally rejects an entirely ordinary baby-photography prompt as `PROHIBITED_CONTENT` / "contains child-related keyword: baby" even though every one of the 300 prompts contains that word; confirmed non-deterministic (see wiro-nano-banana-api memory). `generate_theme_previews.py` is resumable (progress JSON, skips already-done styleIds) specifically because of this kind of flake.
- Home now loads real `previewImageUrl` thumbnails (`ThemeCard`/`ThemeService`/`ThemeCardCell` + a small `RemoteImageLoader` — NSCache-backed, no third-party image library needed yet). Verified visually on simulator with the full 300-style catalog live.

## Backend (Phase 6)
- **Generation flow is synchronous, not webhook-based.** An earlier prototype for this same Firebase project (`~/newbornfunc`, discovered, not reused) used a Wiro `callbackUrl` webhook + FCM push. Per user decision, the new backend has the `generateContent` Cloud Function submit the Wiro task and poll it server-side (~2s interval, 90s timeout) inside one callable invocation, returning the finished result directly — no webhook function, no push notification for this flow.
- **Firestore collections:** `ai_models/{styleId}` (seeded from `Design/Content/theme_catalog.json`, 300 docs: categoryId, categoryName, mood, name, descriptor, prompt, creditCost, aspectRatio), `users/{uid}` (subscriptionCredits, purchasedCredits, isPremium — client can read but only server/Admin SDK can write these fields, enforced in `firestore.rules`), `users/{uid}/generations/{id}` (status, styleId, resultPath, resultUrl), `users/{uid}/milestones/{id}`, `credit_transactions/{id}` (server-only ledger).
- **Storage layout:** `users/{uid}/uploads/*` (client-writable, their own source photos) and `users/{uid}/generations/*` (server-only, written by `generateContent`).
- **Image URLs use Firebase's download-token scheme, not GCS signed URLs** — `getSignedUrl()` needs an IAM permission (`iam.serviceAccounts.signBlob`) not available in this environment; see the playbook pitfalls table and [[firebase-functions-signblob-download-url]] memory. Works identically for the source image (fetched by Wiro, an external server) and the result image (fetched by the Swift client).
- **Credit refund invariant:** once `spendCredits` succeeds, every failure path after it (bad upload path, Wiro outage, any bug) must refund — the `try` block starts immediately after the spend, not just around the Wiro call. Verified end-to-end via `curl` against the deployed function: success deducts correctly, a forced failure (nonexistent source file) refunds correctly, and hitting 0 credits cleanly rejects with `failed-precondition` rather than going negative.
- **Verified end-to-end against the live deployed backend** (not just code review): anonymous sign-in → photo upload → `generateContent` → real Wiro generation → Storage → working download URL → downloaded and visually inspected the actual generated portrait (a "Lion Cub" themed result). `deleteAccount` verified too (Firestore + Storage + Auth user all removed).
- **`AuthService`** signs in anonymously at launch (non-blocking, fire-and-forget per the Stability Gate rule against blocking the first frame). No login wall.
- Home's theme grid now loads from Firestore (`ThemeService`, first 20 of the 300 seeded styles) instead of the 6 hardcoded placeholders — `ThemeCard.samples` was removed.

## Monetization / RevenueCat (Phase 7)
- **RevenueCat project is shared across many of the user's other apps** (project `proj2c0717c6`, "Slapps") — Newborn Studio already existed as app `app62292951bc` with products, entitlement (`newborn`), and an offering (`newborn`, id `ofrngc9d4f47816`) mostly pre-configured from an earlier session. Reused rather than recreated.
- Added the missing `com.newborn.monthly` product (ASC + RevenueCat), attached it to the `newborn` entitlement, and added a `$rc_monthly` package to the `newborn` offering.
- **⚠️ Never touch an offering's `is_current` flag in this account.** It is a project-wide flag, not per-app — setting `newborn`'s to `true` silently flipped another live app's offering (`com.moment.weekly3d`) to `false`. Caught and reverted within the same session; see [[revenuecat-shared-project-is-current-flag]]. **The client fetches the offering by its own identifier (`"newborn"`) instead of `offerings.current`**, so this flag is never touched by the app and doesn't matter going forward.
- Public SDK key: `appl_nxpqIXSXIpYQrsdRfrQwIpDxBrs` (safe to ship — hardcoded in `RevenueCatService.swift`).
- `RevenueCatService` configures at launch (no uid, per Stability Gate — never gate a subsystem on auth), then `identify(uid:)` links it to the Firestore uid once anonymous sign-in resolves.
- **Purchase grant flow matches the playbook (no webhook):** client calls `Purchases.purchase()`, and on success calls the `grantPurchase` Cloud Function directly — trusts that a completed StoreKit transaction is what makes "purchase succeeded" meaningful, not a receipt re-verification. Subscriptions are period-guarded (`subscriptionRenewalDate`) so a re-check doesn't double-grant; consumables always add on top. Verified end-to-end via curl against the live function: grant, double-grant guard, and consumable stacking all correct.
- Paywall and Coin Package screens are now fully data-driven off the live `newborn` offering — verified on simulator with **real App Store pricing** pulled through StoreKit/RevenueCat (Weekly $4.99, Yearly $49.99 "$0.95/week", coin packs $3.99/$6.99/$9.99/$19.99, all matching the ASC-side numbers).
- **Still open (human gates):**
  - `com.newborn.monthly` price ($14.99) — `ascelerate sub pricing set` 409s (known gate, playbook-documented); needs the ASC web UI.
  - Once priced, Monthly needs to actually appear in the paywall — it's already wired (RevenueCat product + package + entitlement exist), just waiting on the price.
  - Real purchases have not been tested (no sandbox Apple ID / physical device in this environment) — only the plumbing (fetch offering, grant function) is verified live.

## Gallery + Home filters (real data, wired)
- **Home category filters are real now**, replacing the 5 fake "New/Trending/Milestones/Fantasy/Seasonal" chips from the mockup (which weren't backed by any real logic — dishonest UI per the playbook's honesty principle). Chips are the 20 real catalog categories plus "All", from a new small `categories` Firestore collection (needed because Firestore has no distinct-query support — deriving 20 categories from 300 `ai_models` docs client-side would mean fetching all 300 just for the filter row).
- **Gallery tab now shows the user's real `generations`** (status == "complete", newest first) instead of the static empty state placeholder; empty state still shows correctly when there are none. Added a `generations` composite index (`status` ASC + `completedAt` DESC) — required since it's an equality filter + orderBy on a different field.
- **Real incident, caught and fully recovered within the session:** re-running `seedThemes` (to add the new `categories` collection) used a plain `.set()` on every `ai_models` doc, which **replaces the whole document** — silently wiping the `previewImageUrl` field that a separate, later script had added to all 300 docs. Home visibly reverted to solid-color placeholder cards, which is how it was caught immediately. Recovery: the actual JPEGs in Storage were untouched (only the Firestore pointer to them was wiped), and the local `theme_preview_progress.json` from the original generation batch still had every `styleId → previewImageUrl` mapping, so a merge-only admin write restored all 300 in one call — no need to regenerate anything. Fixed `seedThemes.js` to use `{merge: true}`. Documented in the playbook pitfalls table since it's a generic Firestore footgun, not specific to this app.

## Secrets
- `WIRO_API_KEY` / `WIRO_API_SECRET` / `REVENUECAT_SECRET_KEY` stored in `.env` (gitignored), never in Claude memory or committed history.
