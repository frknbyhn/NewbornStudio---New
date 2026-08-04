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

## Next
- Continue Phase 5: replace the `RootViewController` placeholder with the real tab-bar Home + remaining screens, wiring the Paywall right after onboarding per the playbook's onboarding→paywall rule.
