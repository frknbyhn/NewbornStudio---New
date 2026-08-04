# Progress

## Phase 0 — Setup
- [x] Machine scan: Xcode 26.2, git, ascelerate (logged in), Firebase CLI (logged in as frknbyhn@gmail.com) all ready.
- [x] Firebase project linked: `newborn-studio` (existing project, reused).
- [x] `functions/` + `public/` scaffolded, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` created.
- [x] `.env` with Wiro credentials, `.gitignore` covering secrets/build artifacts.
- [ ] gcloud not logged in yet — needed later for Blaze billing check.
- [ ] `git init` + first commit — next step.

## Phase 1 — Idea & Scope
- [x] App idea, tech stack (Swift/UIKit, iOS 15+), AI provider (Wiro) confirmed.
- [x] Monetization structure confirmed (see DECISIONS.md) — prices for weekly/yearly subscription and all credit packs still open.
- [x] Name + bundle id confirmed (kept from existing ASC record).
- [ ] Main screens / social layer question still open.

## Phase 2 — Design
- [x] Design pulled from Claude Design project "Newborn Studio App Design" (`9c003995-88f6-4dd1-bd8a-ac345052d187`) via `DesignSync get_file`, saved to `Design/Newborn Studio.dc.html`. Note: `list_projects` doesn't show this project because it's `PROJECT_TYPE_PROJECT`, not a design-system project — `get_project`/`list_files`/`get_file` by id work directly.
- [x] Tokens (colors, fonts, shape language) extracted into DECISIONS.md.
- [ ] Next: build `lib/app/theme` equivalent in Swift (colors, fonts, reusable button/card styles) from these tokens, then implement screens 1:1.

## Resolved
1. All subscription/credit-pack prices pulled live from ASC (see DECISIONS.md) using the `YC2YC44RMZ` API key. `com.newborn.monthly` needs to be created (Phase 7/9).
2. Photo Editor screen cut. Milestone Tracker confirmed private-only, no social layer anywhere in the app.
3. User approved moving forward — next: Swift/UIKit Xcode project scaffold + `Theme.swift` from the extracted design tokens.

## Phase 3 — Xcode Scaffold (Swift/UIKit equivalent of `flutter create`)
- [x] `project.yml` (XcodeGen) — bundle id `com.NewbornStudio`, iOS 15.0 deployment target, Swift/UIKit, no storyboards (programmatic UI + `UILaunchScreen` dict in Info.plist).
- [x] SPM dependencies wired: Firebase (Core/Auth/Firestore/Storage/Functions/Messaging), GoogleSignIn, RevenueCat — resolved successfully via `xcodebuild -resolvePackageDependencies`.
- [x] Folder structure: `NewbornStudio/Sources/{App,Features,Services,Models,Views}`, `NewbornStudio/Resources/{Assets.xcassets,Fonts,Info.plist}`.
- [x] `Theme.swift` — colors/shape tokens from the design mockup, plus a variable-font weight helper (Quicksand/Nunito are variable fonts, not per-weight static files — weight is dialed in via the CoreText `wght` axis, see DECISIONS.md).
- [x] App icon (AI-generated) wired into `AppIcon.appiconset` (single 1024x1024, no alpha). 3 onboarding illustrations wired into named image sets.
- [x] Build verified: `xcodebuild build` → **BUILD SUCCEEDED** for iPhone 17 Pro simulator. Ran on simulator, screenshot confirms cream background + custom Quicksand font rendering correctly (`Design/Screenshots/scaffold_root.png`).
- [x] Git: `.xcodeproj` is committed (regenerate anytime via `xcodegen generate` after editing `project.yml` — that file is the source of truth, not the `.xcodeproj` itself).

## Phase 4 — Firebase
- [x] iOS app was already registered in the `newborn-studio` Firebase project (App ID `1:284818262960:ios:5b8baa16996c499507a475`, bundle id confirmed matching `com.NewbornStudio`).
- [x] `GoogleService-Info.plist` downloaded via `firebase apps:sdkconfig`, wired into the Xcode target, gitignored (not a hard secret but the playbook flags it — regenerate anytime with the same command).
- [x] `FirebaseApp.configure()` added to `AppDelegate`. Verified end-to-end: clean install + launch on simulator, no crash (previously crashed with "could not find a valid GoogleService-Info.plist" until the XcodeGen resources bug above was fixed).
- [ ] Still open from the original Phase 4 checklist: enable Google + Apple sign-in providers in Firebase Console (🙋 human gate), Firestore/Storage rules deploy, Cloud Functions for the actual generation flow — comes with Phase 5/6 once the real screens exist.

## Phase 5 — App Architecture (in progress)
- [x] `AppCoordinator` — single place deciding onboarding vs. home routing, anonymous-first (no login wall), reads/writes `hasCompletedOnboarding` in `UserDefaults`.
- [x] Onboarding (3 slides) built 1:1 from the design mockup: `OnboardingPage` (data model), `OnboardingPageViewController` (per-slide UI: gradient background, circular illustration, title/subtitle, dots, CTA, skip), `OnboardingContainerViewController` (`UIPageViewController` host, swipeable).
- [x] Shared components started: `GradientPillButton`, `PageDotsView`, `HapticFeedback` (centralized tactile feedback per playbook rule).
- [x] Verified: page 1 screenshot matches the mockup closely (gradient, illustration, type, dots, CTA). Verified the onboarding-complete → home-placeholder routing by forcing the UserDefaults flag via `simctl spawn defaults write` and relaunching (no way to script simulator taps, so page 2/3 swipe + Skip/Next button taps were verified by code review, not a live screenshot — flag this to the user for a manual check).
- [ ] Not built yet: real Home (tab bar + theme gallery), Paywall, Photo Upload, AI Generation, Result, Milestone Tracker, Coin Package, Profile screens. Currently `RootViewController` (a bare placeholder label) stands in for Home.

## Phase 5 — App Architecture (screens complete)
- [x] Full flow wired: onboarding → paywall (shown once, right after onboarding) → `MainTabBarController` (Home / Milestones / Gallery / Profile).
- [x] **Home** — theme gallery grid (`UICollectionView`, 2 columns), filter chips, coin balance pill (taps through to Coin Package). Verified on simulator, matches the mockup closely.
- [x] **Paywall** — 3 plan cards (Weekly/Monthly/Yearly, real ASC prices from DECISIONS.md), benefit rows, gradient CTA, working Restore/Terms/Privacy (Terms & Privacy open a placeholder legal modal — real Firestore-backed copy is Phase 6). Verified on simulator; fixed two real bugs found by looking at the screenshot: a badge showing a broken tofu glyph (emoji baked into a label the custom font couldn't render) and "3 DAY FREE TRIAL" clipping outside its pill.
- [x] **Photo Upload** — drop-zone style upload card, tips list, Take Photo / Choose from Gallery wired to a real `UIImagePickerController`. Not screenshot-verified live (simulator has no camera; gallery picker needs a seeded photo library) — verified by code review only.
- [x] **AI Generation (loading)** — simulated progress (real Wiro submit/poll via Cloud Function is Phase 6), matches the mockup's circular progress + rotating status text. Code-reviewed only, not screenshotted.
- [x] **Result** — dark portrait viewer, Save/Share/Retry actions. **The Edit action was deliberately dropped** — Photo Editor is a cut screen per product decision, and playbook rule 4.0 forbids a button that does nothing. Code-reviewed only.
- [x] **Milestone Tracker** — private-only (no sharing, confirmed product decision), done/pending rows. Verified on simulator.
- [x] **Gallery** — empty state (illustration + copy, no bare text) since there's no generation history backend yet. Code-reviewed only.
- [x] **Coin Package** — 4 real packages from DECISIONS.md (small/limited/medium/big), selectable rows, dynamic CTA total. Code-reviewed only, not screenshotted (reachable only via a real tap from Home's coin pill, and the debug-tab hook only covers `MainTabBarController` tabs).
- [x] **Profile** — avatar + "Guest" (anonymous-first, no login wall yet), grouped settings cards. "Contact Support" row was **removed** (playbook explicitly flags this as a common autonomous-run mistake — the store listing's support URL covers this, not an in-app button). "Rate the App" wired to a real `SKStoreReviewController.requestReview`. Verified on simulator.
- [x] Added a `#if DEBUG`-gated `NS_DEBUG_SCREEN` / `NS_DEBUG_TAB` environment-variable hook in `AppCoordinator`/`MainTabBarController` purely to reach screens for screenshot verification without tap automation (no simulator UI-automation tool available in this environment). Compiled out of release builds; still worth grepping for before shipping per the Stability Gate's "no debug affordances" rule.

## Known gaps before this can be considered done (tracked, not forgotten)
- Photo Upload → Generation → Result → Coin Package have not been visually verified on-device/simulator (code-reviewed only) — worth a manual pass.
- All data is hardcoded sample data (`ThemeCard.samples`, `Milestone.samples`, etc.) — Phase 6 replaces this with Firestore.
- No real purchase flow yet (Subscribe/Buy buttons haptic + no-op) — Phase 7 (RevenueCat).
- No real AI generation yet (progress is a local timer, Result shows the *source* photo, not a generated one) — Phase 6 (Cloud Functions + Wiro).
- Legal text is a placeholder modal, not Firestore-backed — Phase 6.5 (admin panel) + Phase 6.
- Anonymous-first auth is assumed but `AuthService`/Firebase Auth sign-in isn't wired yet.

## Phase 6 — Backend (done, verified live)
- [x] `functions/generateContent.js`, `functions/deleteAccount.js`, `functions/lib/{wiro,prompt,credits}.js` written, deployed, and tested end-to-end via direct `curl` calls against the live Cloud Functions (not just code review) — see DECISIONS.md for the exact verification steps and results.
- [x] `ai_models` seeded with all 300 catalog styles via a temporary `seedThemes` function (deployed, curled once, deleted — playbook's one-off admin task pattern).
- [x] Firestore + Storage rules updated and deployed: credits/premium fields are server-write-only, generations are client-read-only, `ai_models` is public-read.
- [x] Swift wiring: `AuthService` (anonymous sign-in), `GenerationService` (upload + call `generateContent`), `ThemeService` (real Firestore themes for Home). `PhotoUploadViewController` → `GenerationLoadingViewController` (real network call, progress bar capped below 100% until the real result lands) → `ResultViewController` (loads the real generated image from its download URL) all wired to the live backend. Build verified green; Home screenshot confirms real catalog data loads (e.g. "1920s Flapper", "Alice in Wonderland").
- [x] Two real bugs found and fixed while verifying against the live backend (not caught by code review alone): `getSignedUrl()` failing on missing IAM permission (switched to Firebase's download-token URL scheme), and a credit-refund gap where a failure between spending credits and the original narrow `try` block would silently lose the user's credit with no refund.
- [ ] Not done: `grantPurchase` (RevenueCat, Phase 7), Firebase App Check / rate limiting (Phase 14), legal text still placeholder (not Firestore-backed yet), Home's filter chips are still visual-only (not wired to `categoryId` queries), Gallery tab still shows the static empty state rather than the user's real `generations`.

## Next
- Phase 7: RevenueCat monetization — wire the real subscribe/purchase flow, `grantPurchase` Cloud Function, replace the Paywall/Coin Package screens' no-op buttons with real StoreKit purchases.
