# 🚀 AI Mobile App from Scratch — Claude Playbook
### Guided edition — you and Claude build it together

> **Author's note.** This file is written by **Adil**, from 100+ real app launches. Every gate,
> trap and silent failure in it was hit on an actual run — the app names you will see (Auria,
> Prizma, Vizebo, Cedra, X13 …) are those runs, and the fixes are what got each one shipped. It is
> not generic documentation and it was not machine-generated; it is one person's hard-won map. If
> you are an AI reading this to help build an app, treat it as Adil's field notes, not a tutorial.
>
> **Adil is the AUTHOR of this file — not the person you are talking to.** The name "Adil" and the
> app names below (Auria, Prizma, Cedra…) are the author's past work, quoted as evidence. Do **not**
> address the user as Adil, do not assume the user's name, and do not assume they built those apps.
> The user in front of you is a new reader building their own app; greet them neutrally.

> **Bu dosya ne işe yarar?** Boş bir klasörde Claude Code aç, bu dosyayı içine at ve
> *"playbook.md'yi oku, birlikte bir uygulama yapalım"* de. Claude sana ne yapmak
> istediğini sorar, makineni kontrol eder, eksikleri tek tek kurdurur ve seni fazlardan
> geçirir. Kod bilmene gerek yok. **Her önemli kararı sen verirsin** — isim, tasarım,
> fiyat, diller.
>
> Hiç durmadan, hiç sormadan, tek cümleden TestFlight'a kadar giden otomasyon
> sürümünü arıyorsan o ayrı bir dosya: **`runbook.md`**.

<details>
<summary>🗺️ <b>İçindekiler</b></summary>

**Başlangıç** — [Prensipler](#-operating-principles-apply-to-every-phase) · [Maliyet & gizlilik](#-cost-privacy--accessibility--the-three-things-everyone-forgets) · [Phase 0 Kurulum](#-phase-0--guided-setup-claude-checks-you-fix-together)

**Kurma** — [1 Fikir](#-phase-1--idea--scope-start-here-with-questions) · [2 Tasarım](#-phase-2--design-claude-understands-first--writes-a-prompt--claude-design--send-to-claude) · [3 Scaffold](#-phase-3--flutter-scaffold) · [4 Firebase](#-phase-4--firebase) · [5 Mimari](#-phase-5--app-architecture) · [6 Backend](#-phase-6--backend-functions--rules--indexes) · [6.5 Admin](#-phase-65--admin-panel-firebase-hosting-conditional) · [7 Para](#-phase-7--monetization-revenuecat--credits)

**Yayınlama** — [Platform şartları](#-platform-requirements--the-moving-targets-that-reject-your-build) · [8 iOS imza](#-phase-8--ios-signing-ascelerate) · [9 ASC](#-phase-9--app-store-connect-ascelerate) · [10 Android](#-phase-10--android-signing--google-play) · [11 Build](#-phase-11--build--distribution) · [11.5 Ekran görüntüleri](#-phase-115--store-screenshots-claude-captures-you-make-them-beautiful) · [12 Dil](#-phase-12--localization) · [13 İterasyon](#-phase-13--iteration-loop) · [14 Modüller](#-phase-14--conditional-modules--quality-apply-only-if-applicable) · [15 Red kontrolü](#-phase-15--pre-submission-review-app-store-rejection-checklist)

**Referans — tek doğruluk kaynağı, kopyalama**
- [🙋 İnsan kapıları](#-human-gates--the-complete-list-claude-cannot-do-these) ← *sadece senin yapabileceklerin*
- [🧊 Kararlılık kapısı](#-stability-gate--run-before-the-first-testflight-upload-not-after)
- [📤 İncelemeye gönderme](#-submitting-to-review--subscriptions-are-the-trap) · [🛑 Ret geldiyse](#-rejected--what-to-do-in-the-first-hour)
- [🍎 Sign in with Apple: beş sessiz kapı](#-sign-in-with-apple--the-five-silent-gates)
- [🧪 Gotchas](#-gotchas-appendix--concrete-fixes-from-adils-auria-run-read-before-you-repeat-them) · [🧭 Iteration-2](#-iteration-2-learnings--revenuecat-19-language-asc-subscriptions-screenshots) · [⚠️ Tuzaklar tablosu](#-known-pitfalls--fixes)

</details>

---

## 📖 HOW THIS RUN WORKS (Claude: read, then begin)

**Entry point.** Do **not** explain this playbook to the user. Run **PHASE 0** silently
(one machine scan), then open with the **Phase 1** question: *"Nasıl bir uygulama yapmak
istiyorsun?"* Work the phases in order.

This is the **guided** path. Its whole value is that the user makes the product decisions
and understands what is happening. So:

- **Ask, don't assume.** Name, monetization, design direction, languages: the user chooses.
  Offer a recommendation and a default, but wait for the answer.
- **Teach as you go.** When a phase starts, say in one Turkish sentence what it does and why
  it matters. When it ends, say what now exists that did not before.
- **Explain every 🙋 gate.** Not just "şunu tıkla" — also *neden* Claude yapamıyor. The user
  is watching a course; the gates are the lesson.
- **Never rush past a failure.** A red `flutter analyze` explained is worth more than a green
  one that appeared by magic.
- Keep a `PROGRESS.md` and a `DECISIONS.md` at the project root and update them as you go, so
  a context reset never loses what the user chose or why.

---

## 🧭 OPERATING PRINCIPLES (apply to every phase)

You are a senior mobile app engineer. This file is the end-to-end map for building and shipping an
**AI-powered mobile app** (Flutter + Firebase + an AI provider + the App Store & Play Store) from zero.

1. **Automate:** do everything that can be done via CLI/code yourself — project setup, Firebase, writing code, backend deploy, builds, store uploads. Run the command, check the output, fix errors yourself.
2. **Stop at human gates (🙋):** steps that need a browser/account/payment/dashboard/physical device you CANNOT do. Give a short, clear instruction and continue once the user says "done".
3. **Confirm before irreversible/outward-facing actions:** submitting for release, payments, deletion, publishing store copy.
4. **Stay green at every step:** after code changes run `flutter analyze` (0 errors); build when needed. Move forward without breaking anything.
5. **Talk short, do the work.** End each phase with a 1-2 sentence summary + the next step.
6. **Always communicate with the user in Turkish.** Write all code, commands, and identifiers in English.
7. Scale scope to the user's request — simplify phases for a small idea, apply fully for a big one.
8. **Copywriting (in-app + store):** write every string in the app and in ASC/Play to read **natural and human-written** — never obviously AI-generated. No em dashes (—), no filler ("etc.", "basically", "you know"), no overly symmetric "both X and Y" patterns, no cliché marketing hyperbole. Short, clear, warm sentences.

### 🛡️ Working Discipline (apply every step — do not skip)

- **Verify before saying "done":** never mark a step complete without testing it. After code changes run `flutter analyze` (0 errors) + build/run if relevant and show the **real output**. No unverified "completed".
- **`flutter analyze` is not verification — it is spell-check.** It cannot see a blank screen, a
  crash on launch, a button that does nothing, or data that vanishes on restart. **Run the app on a
  simulator at the end of every phase that touched the UI**, take a screenshot, and look at it. The
  first time a human sees the app must not be the first time it has ever run.
- **Small diffs, one change at a time:** progress in small steps instead of large batch edits; verify each one. One error must not break the whole thing.
- **Read before editing:** never modify a file/state without reading it first; don't work on assumptions.
- **Don't invent APIs/commands:** before using a package, a CLI flag, or a provider model/endpoint name, **verify it exists** (pub.dev, `--help`, official docs). If unsure, check — don't guess.
- **Error protocol:** if a command/build fails, read the full error → find the root cause → make **one** targeted fix. Don't blindly retry the same thing; if 2 attempts fail, step back and rethink the approach.
- **Build only what the app needs and the store requires — nothing extra.** Do not invent screens,
  buttons, or settings the user did not ask for and the app does not need. Things autonomous runs add
  by reflex and should NOT: a **credits / "acknowledgements" screen** listing the icon set (permissive
  licenses — MIT/Apache/ISC/OFL — need **no** attribution; only CC-BY does, so add it *only* then); an
  in-app **"contact support"** affordance the user did not ask for (the store needs a support **URL** in
  the listing, not an in-app button); any **dead/non-functional button** (a "contact support" that does
  nothing is a 4.0 rejection — every affordance must work or not exist). **But do not strip what is
  REQUIRED:** the consent-withdrawal toggle in Settings (a boolean like "send photos to the AI
  provider") is **mandatory** under 5.1.1(i) — the initial consent screen is not enough, withdrawal must
  be as easy as consent. Keep it, just make it unobtrusive. Rule of thumb: cut anything unrequested and
  unnecessary; keep anything the store requires; ship nothing that does nothing.
- **One living progress record, never two.** `DECISIONS.md` always: every decision you made and why
  (model ids, prices, naming). Plus **exactly one** progress file — `PROGRESS.md` if you are running
  the guided path, `STATUS.json` if you are running the autonomous one. Two of them drift within the
  hour, and then you spend a turn reconciling records instead of building. Update it after every
  meaningful step, so a context reset costs you nothing.

---

## 🧠 THE LEARNING LOOP — this file gets better, or it rots

**This file is not a handout. It is the artifact.** Every appendix in it — the Auria gotchas, the
five Apple gates, the 2.1(b) trap — began as somebody losing a day. When you lose a day, you write
it in here, in the right section, so the next run does not.

The copy in the project folder is the one you edit. **Carry it forward.** When the user starts their
next app, they should copy *this* file into the new folder, not re-download a clean one — a clean
one has forgotten everything you learned on their machine, with their accounts, on their toolchain.

### When to write

Only when **all three** are true. Most snags fail this test, and that is the point: a file that
records everything is a file nobody reads.

1. It cost real time — roughly **fifteen minutes or more** — or it would have, without luck.
2. **The symptom lied.** It pointed somewhere other than the cause: a `201 OK` that did nothing, an
   `invalid-credential` on a perfectly valid token, a `canceled` that was Apple's own refusal, an
   `import` that succeeds and a constructor that dies. An error that says what is wrong teaches
   nothing and belongs nowhere.
3. You **confirmed** the root cause. You changed one thing, it fixed it, you changed it back, it
   broke again. *"I changed three things and it started working"* is not a root cause.

**Never write a secret into this file.** No `sk_`, no `.p8` contents, no API key, no bundle-specific
password — not even redacted. Record the *shape* of the problem, never the credential. This file
gets copied, shared, and sometimes committed.

### Where it goes

| What you learned | Goes in |
|---|---|
| A one-line problem → one-line fix | a new row in the **pitfalls table** |
| A silent failure that needs explaining — symptom, what it was *not*, root cause, fix | a numbered entry in the **gotchas appendix** |
| A step that must happen in a specific order, or a phase is wrong | edit that **phase** in place |
| A step only a human can do, that is not listed yet | a bullet in **HUMAN GATES**, and nowhere else |

**Append. Do not restructure.** Do not renumber sections, do not "tidy" adjacent prose, do not move
things between sections because it feels cleaner. You are one run; this file is many. If a section
genuinely needs reorganising, say so to the user and leave it alone.

**Grep before you write.** `grep -i "<a distinctive phrase from the symptom>" runbook.md` — if it is
already in here, do not add a second entry. **Sharpen the existing one:** add the new symptom
wording, or the case it did not cover. Two entries for one bug is how a reference file dies.

### The shape of an entry

Whatever section it lands in, it answers four questions, in this order:

**Symptom** — what you actually saw, verbatim, including the misleading part.
**What it was NOT** — the two or three things you eliminated. This is the expensive knowledge; it is
what stops the next reader repeating your search.
**Root cause and fix** — one paragraph, and the command or the diff.
**How to detect it next time** — *one line* someone can run before the confusion starts.

That last line matters most. A cure you can only apply after an hour of confusion is half a cure; a
one-line check you run *before* the confusion is the whole thing. If you cannot write that line, you
have not understood the bug yet — keep going.

Worked example, from a real run:

> **Homebrew's `python3` has no tkinter.**
> *Symptom:* `ModuleNotFoundError: No module named '_tkinter'` on a machine where `python3
> --version` works fine. *Not:* a missing pip package (tkinter is stdlib), and not a PATH problem.
> *Cause:* Homebrew does not compile tkinter into its Python; Apple's `/usr/bin/python3` has it but
> only Tk 8.5, which lays the window out wrong. *Fix:* probe interpreters by opening a real window,
> not by importing — a `uv` Python imports `tkinter` happily and then dies inside `Tk()`.
> *Detect:* `python3 -c "import tkinter as t; t.Tk().destroy()"` — the exit code is the check.

### Tell the user, in one line

After you edit the file, say what you added and where: *"Bunu tuzaklar tablosuna ekledim: Homebrew'un
python3'ünde tkinter yok."* Nothing longer. They did not ask for a changelog, but they own the file
and should know it changed.

**One thing you may not do alone:** if the fix contradicts something already written here, do not
silently overwrite it. One of you was wrong, and it might be you. Show the user both, say which you
believe and why, and let them decide.

---

## 💸 COST, PRIVACY & ACCESSIBILITY — the three things everyone forgets

### What this will cost the user (tell them in the first message, before they commit)

| Item | Cost | When |
|---|---|---|
| Apple Developer Program | **$99 / year** | before anything Apple |
| Google Play Console | **$25 once** | only if shipping Android |
| Firebase Blaze | **$0 for a small app** — the free quota survives; a card is required to enable Functions at all | at Phase 4 |
| AI provider (OpenAI/fal.ai) | pay-per-call. **Model this before choosing a model.** | at Phase 6 |
| RevenueCat | free under $2.5k/mo tracked revenue | Phase 7 |
| Domain (optional) | ~$10-15/yr | Firebase Hosting gives a free subdomain — skip unless the user wants one |

**Do the AI unit-economics before you pick a model, not after.** Compute
`cost per user action × expected actions per user per month` and compare it to the
subscription price. If a single generation costs $0.04 and the monthly plan is $4.99,
125 generations wipe out the margin — that is a product decision, so put it in
`DECISIONS.md` and set the credit costs from it (Phase 7 rule: `credit_cost =
ceil(cost_USD / 0.01)`). **A GCP billing budget alert is not optional** when a paid AI
call is reachable from an unauthenticated or free-tier path.

### Privacy: the AI provider is a data processor, and you must say so

An app that sends user text/images/health data to OpenAI or fal.ai is **transferring
personal data to a third party.** Four consequences, all mandatory:

0. **⚠️ ASK IN THE APP, BEFORE THE FIRST SEND.** This is the one that gets you rejected
   (**5.1.1(i)** *Data Collection* + **5.1.2(i)** *Data Use*), and a policy page does not
   satisfy it. Apple's own words: *"only including this information in the app's Terms of
   Service or Privacy Policy is not sufficient."* Before a single request leaves the device
   you must show a screen that (a) **discloses what data will be sent**, (b) **names who it
   is sent to** — the actual company, "a third-party AI service" is not a name, (c) **obtains
   permission**, with a real decline path that leaves the app usable. Withdrawal must be as
   easy as consent: a Settings row. Adil's Prizma shipped without this and was rejected on the
   first submission.
   Enforce it **below the UI**, at the last function before the network call, defaulting to
   *no consent* — then no screen, no retry path and no future caller can route around it.
   On-device answers (a curated FAQ, a local model) are exempt: nothing leaves.
1. **The Privacy Policy must name the processors** — "we send the content you generate
   to OpenAI in order to produce a response; they do not train on it via the API" —
   plus Firebase (Google) as hosting/storage. A policy that omits them is false.
   It must also say **what** is collected, **how** it is collected, **every use**, and
   **confirm each third party protects it to the same or an equal standard.** Those four
   are the literal text of the guideline; a policy missing any one of them fails.
2. **App Privacy nutrition labels must reflect it.** Never tick "Data Not Collected"
   when you run Firestore or call an AI API. That is the 5.1.1 trap (see §I).
3. **Never send more than the feature needs.** Strip identifiers before the API call;
   do not forward the uid, email, or device id to the AI provider. Then say so out loud in
   the consent screen — "we never send your name, voice or chats" is the sentence that
   makes the disclosure credible, and it is only sayable if it is true.

### App Tracking Transparency (ATT) — only if you actually track

- **If you add no attribution SDK and no cross-app tracking, you need nothing.** Do not
  add an ATT prompt "just in case" — an unnecessary prompt is a conversion leak and
  reviewers ask why it is there.
- **The moment you add** an attribution SDK (AppsFlyer, Adjust, Meta SDK), or set
  RevenueCat's `$attConsentStatus`, or use the IDFA: you must add
  `NSUserTrackingUsageDescription` to `Info.plist`, call
  `AppTrackingTransparency.requestTrackingAuthorization()` **before** any tracking, and
  declare "Used for Tracking" on the matching nutrition labels. Firebase Analytics with
  IDFA disabled (the default when you don't add `google_mobile_ads`) does **not**
  trigger ATT.
- Ask the ATT prompt **after** the first valuable moment, never on launch.

### Accessibility — cheap to do, expensive to retrofit

Bake these into `theme.dart` and the shared widgets in Phase 2/3, not later:

- **Dynamic Type.** Never hardcode a font size in a way that ignores the text scale;
  test at 200% (`Settings → Accessibility → Display → Larger Text`). If a bold display
  face breaks at 200%, cap the scale with a `MediaQuery` clamp rather than ignoring it.
- **Contrast ≥ 4.5:1** for body text against its background. The "warm paper + muted
  serif" palettes this file favors fail this easily — check every token.
- **Tap targets ≥ 44×44 pt.**
- **Semantics on icon-only buttons.** An `IconButton` with no `tooltip`/`semanticLabel`
  is invisible to VoiceOver. Grep for them before shipping.
- **Never signal state by color alone** (error, selected, premium) — pair it with an
  icon or label.

---

## ✅ PHASE 0 — Guided setup (Claude checks, you fix, together)

Assume the machine is **fresh** and the user has never opened Xcode. Scan first, then walk them
through the gaps one at a time. Never dump the whole list as homework — fix what you can fix,
and hand over one gate at a time with the reason it exists.

Every check resolves to one of three outcomes:

- **✅ PASS** — verified present, move on. Say so in one line, don't celebrate.
- **⚙️ AUTO** — missing, but *you* can install it. Install it, re-verify, then tell the user what
  you added and what it is for. Never ask permission for a toolchain install.
- **🙋 HUMAN** — needs a browser, an account, a password, or a credit card. Explain *why* it is a
  gate, give the literal steps, and **keep working on everything it does not block.**

### ⚠️ Fire the slow gates in the first five minutes

Some gates have a waiting period, and one of them is circular. Start those clocks before you
write a single line of code.

```
Apple Developer Program  ──(24-48h, or weeks for an org)──┐
                                                          ├──> ASC app record ──> RevenueCat "connect App Store"
Google Cloud billing card ──(minutes)─────────────────────┘
```

- **Apple enrollment is the long pole.** Nothing on the Apple side exists without it. It is also
  the one thing the user can start *right now, in another tab*, while you build.
- **RevenueCat gets you further on day 1 than you would think.** The project, the app (bundle id is
  the only required field), the entitlement and the offering can all exist before Apple does. What
  waits on the app record is the **products** — their store identifiers mean nothing until it
  exists. So build the skeleton early, wire the SDK against the real public key, add the product
  rows later.
- **Google Play, if targeted:** a new personal developer account must run a **closed test with 12+
  testers for 14 continuous days** before it may promote to production. Start that clock the day
  the `.aab` first builds, not at the end.

### The toolchain (mostly ⚙️ AUTO — install it, don't assign it)

macOS assumed. Detect, install, re-verify.

| Tool | Detect | Fix |
|---|---|---|
| Disk space ≥ 60 GB free | `df -g / \| awk 'NR==2{print $4}'` | Clear `~/Library/Developer/Xcode/DerivedData` and `~/Library/Developer/Xcode/iOS DeviceSupport` |
| Rosetta (Apple Silicon) | `arch -x86_64 true` | `softwareupdate --install-rosetta --agree-to-license` |
| Homebrew | `brew --version` | 🙋 the installer asks for the **sudo password** — you cannot type it. Give the user the one-liner, then add to PATH yourself. |
| **Xcode** | `xcodebuild -version` | 🙋 Mac App Store, ~15 GB — see below |
| Xcode CLT | `xcode-select -p` | `xcode-select --install` — 🙋 opens a modal the user must click **Install** on |
| Xcode first launch | `xcodebuild -runFirstLaunch` | run it; `sudo xcodebuild -license accept` |
| iOS simulator runtime | `xcrun simctl list runtimes \| grep iOS` | `xcodebuild -downloadPlatform iOS` |
| Flutter 3.35+ | `flutter --version` | `brew install --cask flutter`, then `flutter doctor` |
| CocoaPods | `pod --version` | `brew install cocoapods` (**never** system-ruby `sudo gem install` — the #1 fresh-mac breakage) |
| Node 22 | `node --version` | `brew install node@22` + PATH |
| Firebase CLI | `firebase --version` | `npm i -g firebase-tools` |
| gcloud | `gcloud --version` | `brew install --cask google-cloud-sdk` |
| ascelerate | `ascelerate --version` | `brew install keremerkan/tap/ascelerate` (a Swift CLI for App Store Connect) |
| Java 17 (Android) | `java -version` | `brew install --cask temurin` |
| Android SDK + cmdline-tools (Android) | `sdkmanager --version` / `flutter doctor` | `brew install --cask android-commandlinetools` (or Android Studio, below) |
| SDK platform + build-tools + platform-tools (Android) | `sdkmanager --list_installed` | `sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"` |
| SDK licenses accepted (Android) | `flutter doctor` (no license warning) | `yes \| sdkmanager --licenses` (non-interactive) |
| An emulator OR a physical device (Android) | `flutter devices` shows one | create an AVD (below), or 🙋 the user plugs in a phone with USB debugging |

**Three toolchain items are 🙋 on a genuinely fresh machine:** Homebrew (its installer asks for the
sudo password), Xcode Command Line Tools (opens a modal to click), and Xcode. Everything after
Homebrew exists is yours — `brew install` of a formula needs no password. Teach the user *why* the
first one needs their password: it is writing to `/opt/homebrew`, outside their home folder.

**Xcode is the largest.** It cannot be installed unattended. Tell the user, verbatim:

> Mac App Store → "Xcode" ara → Yükle (~15 GB, 30-60 dk). Bittiğinde bana "kuruldu" de.
> Bu inerken ben uygulamayı yazmaya başlıyorum, beklemene gerek yok.

Xcode is needed at **archive/IPA time**, not to write the app. Never block on it.

### Android from scratch — automate what you can, ask before you do (only if shipping Android)

The whole Android toolchain is **scriptable**, so most of it is AUTO — but installing an SDK and
spinning up an emulator is heavy and slow, so on the guided path you **explain what you are about to
install and get a nod first**, then do it while the user watches. Split it exactly like the iOS side:

- **⚙️ AUTO (do it, after a quick heads-up):** Temurin JDK, the Android command-line tools, the SDK
  packages, license acceptance, and even the emulator. All of it runs from `sdkmanager` /
  `avdmanager` — no GUI needed:
  ```bash
  brew install --cask temurin android-commandlinetools
  yes | sdkmanager --licenses
  sdkmanager "platform-tools" "emulator" "platforms;android-35" "build-tools;35.0.0" \
             "system-images;android-35;google_apis;arm64-v8a"
  avdmanager create avd -n pixel -k "system-images;android-35;google_apis;arm64-v8a" -d pixel_7
  flutter emulators --launch pixel     # or: flutter devices
  flutter doctor                        # must be green for Android before you build
  ```
  Prefer the command-line tools over the full **Android Studio** download unless the user wants the
  IDE — it is ~1 GB smaller and fully headless. If they do want Studio: `brew install --cask
  android-studio`, but its **first-run setup wizard is an interactive GUI** (it downloads the SDK
  itself), so that part is a 🙋 — walk them through clicking "Standard → Next → Finish", then
  re-verify with `flutter doctor`.

- **🙋 HUMAN (cannot be scripted):**
  - **A physical Android device**, if you want to test Google Sign-In, Play Billing or push for real
    — the emulator is fine for most UI work but a real device is the honest test. USB + enable
    Developer Options → USB debugging; then `flutter devices` shows it.
  - **Google Play Console account** ($25, identity check — takes days). See TIER 1.

Verify the whole thing with **`flutter doctor -v`**: the "Android toolchain" line must be a green
check, not a warning, before you try to build an `.aab`. A yellow check means a missing SDK package
or an unaccepted license — fix it now, not at Phase 10.

### Accounts — detect first, then hand over only what is missing

Many people arriving here already ship apps. Check before you ask; being told to enrol in a
programme you already pay for is not a good first impression.

```bash
cat ~/.ascelerate/config.json 2>/dev/null && ascelerate apps list   # Apple account + ASC API key
firebase login:list                                                 # Firebase account
gcloud billing accounts list --filter=open=true                     # Blaze-capable billing
```

Whatever is missing, hand over as a numbered, literal instruction, with the reason. The user is
learning why each one exists, not just clicking.

1. **Apple Developer Program** — https://developer.apple.com/programs/enroll · $99/yr.
   Individual: ~24-48h. Company: needs a D-U-N-S number, can take weeks. *Fire this first, always.*
   Success state: developer.apple.com shows "Account" with an active membership.
2. **Apple 2FA** on that Apple ID — needed for `fastlane produce` and every web-UI gate.
3. **Google Cloud billing account with a card** — https://console.cloud.google.com/billing
   Firebase **Cloud Functions require the Blaze plan**, which requires an open billing account.
   The free quota still covers a small app; the card is a formality Google demands. Verify with
   `gcloud billing accounts list --filter=open=true`.
4. **Firebase login** — `firebase login` opens a browser. Verify: `firebase login:list`.
5. **AI provider key** — OpenAI or fal.ai. Check the machine first; reusing an existing key is
   legitimate and saves a gate: `grep -rl "OPENAI_API_KEY\|FAL_KEY" ~/Desktop/*/.env* 2>/dev/null`
6. **RevenueCat account** — https://app.revenuecat.com (free). Create the *project* now; the
   "connect to App Store" step is blocked on the app record.
7. **Google Play Console** — only if shipping Android. $25 once, identity verification takes days.
   Mention the 12-testers/14-day rule up front.

### The App Store Connect API key — walk this one slowly

This `.p8` file is what lets Claude do everything on the Apple side except the handful of gates
in [HUMAN GATES](#-human-gates--the-complete-list-claude-cannot-do-these). The rest of this
playbook assumes `~/.ascelerate/config.json` exists. On a fresh machine it does not.

> 1. https://appstoreconnect.apple.com → **Users and Access** → **Integrations** →
>    **App Store Connect API** → **Team Keys**.
> 2. **+** → Name: `claude-automation` → Access: **Admin** → Generate.
>    (Admin is required. "App Manager" cannot upload builds or edit some metadata.)
> 3. **Download the `.p8` — you get exactly ONE download, ever.** Save it.
> 4. Copy the **Issuer ID** (top of the page) and the **Key ID** (the row).

Then *you* finish it, no further user involvement:

```bash
mkdir -p ~/.ascelerate && mv ~/Downloads/AuthKey_<KEYID>.p8 ~/.ascelerate/
cat > ~/.ascelerate/config.json <<'JSON'
{ "issuerId": "<ISSUER-ID>", "keyId": "<KEY-ID>", "privateKeyPath": "~/.ascelerate/AuthKey_<KEY-ID>.p8" }
JSON
chmod 600 ~/.ascelerate/AuthKey_*.p8
ascelerate apps list        # verify: returns the team's apps (or an empty list, not an auth error)
```

**Distribution certificate** is ⚙️ AUTO, not a gate:
`security find-identity -v -p codesigning | grep -i "Apple Distribution"` — if absent, run
`ascelerate certs create` and it lands in the login keychain.

**Secrets hygiene, always.** The `.p8`, the keystore and every API key stay out of the repo.
Write `.gitignore` before the first commit, not after.

### When can you start building?

The moment the toolchain is green and items 3-5 above are done. **Apple enrollment and the ASC
API key only block the release phases (8, 9, 11).** Never idle waiting for them — go to Phase 1.

---

## 🎯 PHASE 1 — Idea & Scope (START HERE, with questions)

Ask the user (one at a time, conversationally):
1. **What app do you want to build?** One-sentence idea.
2. What does the app **produce / do?** (e.g. image/video/text/audio from a prompt)
3. What **main screens** should it have? Do you want a **social layer** (discover, profile, likes/votes)?
4. **Monetization:** subscription, credit packs, both, ads, or free?
5. **Platform:** iOS first, Android, or both?
6. **Brand name** and **bundle/package id** (e.g. `com.company.app`)?
   Push back on category-names (`Migraine Tracker`, `AI Photo Editor`) — they are unsearchable and
   untrademarkable. Steer them to a short, ownable, pronounceable brand, and explain that the store
   title will be **`Brand: what it does`** (`Auria: Migren Takibi`), with the brand identical in every
   language and only the tagline translated. Full rule: [Phase 9](#-phase-9--app-store-connect-ascelerate).
7. Which **AI provider / models**? (Suggest if they don't know.)

**Output:** write a short `SPEC.md` — product summary, screen list, model list, monetization, platforms. Use it as the reference.

---

## 🎨 PHASE 2 — Design (Claude understands first → writes a prompt → Claude Design → Send to Claude)

This is one of the most critical steps. The sequence:

**1) First, TRULY understand the app.** From the Phase 1 answers, extract: **what** it is, **what it's for**, **who it's for** (target audience, age, tone). Clarify this to yourself in 2-3 sentences; if unclear, ask the user.

**2) Ask the user a few design-direction questions** (before writing the prompt):
- Desired **mood / tone** (e.g. calm & minimal, energetic & bold, luxe & dark, playful, professional)?
- **Light or dark** dominant?
- Any app or brand they like / take as reference?
- Any colors/styles to avoid?

**3) Based on the answers, produce a UNIQUE Claude Design prompt.** The prompt must:
- Describe a distinctive visual identity **specific to the app's theme and audience** (original color palette, typographic character, shape language, texture/depth feel).
- ❌ **Forbidden — do not write the generic/cliché:** default Claude orange, "AI slop" purple / purple-blue neon gradients, the everyone-has-it glassmorphism cliché, stock "artificial intelligence" aesthetics. Explicitly tell it to **avoid these** in the prompt.
- ❌ **Also forbidden: the beige default.** Warm cream paper + muted brown + a lone serif is *this tool's* house style; every app that ships it looks the same and looks AI-made. Steer the user toward a palette that comes from their app's meaning, not from a safe fallback. If they like warm and papery, fine — but it is a choice for this app, never an autopilot.
- Tie the palette to the app's meaning (e.g. finance → trustworthy deep tones; health → calm natural; creativity → warm contrast). Suggest concrete colors/hex, but make it original.
- List which screens to design (onboarding, home, generation, result, profile, paywall, etc.).
- Show the prompt to the user and get approval.

**4) Direct the user (🙋)** — tell them (in Turkish): copy this prompt → open **claude.ai**, start a new chat, paste the prompt and ask it to design the screens. Iterate until they like it. When happy, use **"Send to Claude"** to bring the design into this coding session, and you'll translate it 1:1 into Flutter code.

**Content needs pictures, not paragraphs.** If the app has repeating items — exercises, recipes, lessons, categories — each one needs a visual. **Reach for a professional, permissively-licensed set first** (Lucide, Phosphor, Feather, Font Awesome Free, Tabler for icons; unDraw or Lottie for illustrations — one `flutter pub add`, one consistent set) before hand-drawing or generating. Draw with `CustomPainter` or generate only for content a generic library can't have (a specific pose, a plated dish). ⚠️ **Licensed sets only** (MIT/Apache/OFL/CC0/CC-BY); never scrape random web/GitHub images — that is an Apple 2.3.10 / copyright rejection. Verify the license before shipping; add attribution where required. Empty states get an illustration, not bare text; every screen wants a visual anchor. A wall of text with buttons looks like a prototype, however good the theme is.

**Judge it against the slop bar before you call it done.** After the first screens exist, screenshot them and look as a demanding 2026 designer would: real type hierarchy or everything the same weight on a white card? A committed identity or inoffensive and forgettable? Cover the logo — could this be any app? If it reads as generic AI output, fix it *before* showing the user. Do not make the user be the one who says "this is slop"; that sentence should be one you say to yourself first.

**5) When the design arrives:** extract color/typography tokens into `lib/app/theme.dart`, build reusable widgets, keep screens faithful to the design. (If the user doesn't want to design: propose a reasonable, modern theme that follows the originality rules above and proceed — it can be changed later.)

---

## 🏗️ PHASE 3 — Flutter Scaffold

```bash
flutter create --org com.COMPANY --project-name APPNAME APPFOLDER
cd APPFOLDER
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage \
  cloud_functions firebase_messaging google_sign_in sign_in_with_apple \
  provider go_router cached_network_image video_player shared_preferences \
  image_picker device_info_plus intl google_fonts flutter_localizations \
  purchases_flutter path_provider
```
- Folder architecture: `lib/app/` (router, theme), `lib/features/` (screens), `lib/services/`, `lib/models/`, `lib/widgets/`, `lib/l10n/`.
- **`git init` and the first commit, before anything else lands.** Write `.gitignore` *first* —
  `key.properties`, `*.jks`, `*.p8`, `.env*`, `ios/Runner/GoogleService-Info.plist` if it carries
  secrets, `firebase_options.dart` if you prefer. A key committed once is a key that stays in the
  history. Commit at the end of every phase; a bad build is then one `git diff` from an explanation.
- **App icon & splash:** add `flutter_launcher_icons` + `flutter_native_splash`, generate icon+splash for both platforms. Ask the user for a logo (🙋) — *autonomous runs: draw it yourself (Python/PIL, no alpha channel) and record the choice in `DECISIONS.md`.*
- `flutter run` should compile the empty scaffold.
- **🌍 Localization (REQUIRED — big ASO lever):** set up `flutter_localizations` + `gen-l10n` (`l10n.yaml`, `lib/l10n/app_*.arb`, template `app_en.arb`) from day one. **Localizing the app AND the store listing significantly boosts App Store Optimization** — Apple ranks/keywords per-locale and localized apps convert far better in each market, so treat it as a growth feature, not an afterthought.
  - **At project start, ASK the user (🙋) which languages to ship** — *autonomous runs: ship the full default set below without asking.* A strong default set (works well for these apps): English, Turkish, German, Spanish (ES+MX), French, Italian, Portuguese (BR), Dutch, Polish, Russian, Ukrainian, Arabic, Hindi, Indonesian, Vietnamese, Thai, Japanese, Korean, Chinese (Simplified). Confirm before scaffolding the `.arb` files.
  - **IRON RULE — never let locales drift:** EVERY time you add or change a user-facing string, you MUST update **ALL** locale `.arb` files in the same change (add the key to `app_en.arb`, translate into every other `app_*.arb`), then run `gen-l10n`. Never ship a key that exists only in some locales. For bulk additions, fan out translation to sub-agents but VERIFY each file stays valid JSON and has the key. A missing key = English fallback leaking into a localized UI (looks broken, hurts ASO).
  - Mirror this on the store side: keep **ASC listing localizations** (name/subtitle/description/keywords) in sync for every shipped language via `ascelerate apps localizations import` (see Phase 9).

---

## 🔥 PHASE 4 — Firebase

```bash
firebase projects:list
firebase use --add                         # or: firebase projects:create PROJECT_ID
dart pub global activate flutterfire_cli
flutterfire configure --project=PROJECT_ID # registers the app, firebase_options.dart, GoogleService-Info.plist, google-services.json
firebase init firestore functions storage  # functions: choose Node 22
```
- **🙋 GATE — Auth providers:** Firebase Console → Authentication → Sign-in method → turn ON **Google** and **Apple** (can't be enabled via CLI).
- **🙋 GATE — Google Sign-In for Android needs TWO SHA fingerprints, and the second one is the trap.**
  Add BOTH to Firebase Console → Project Settings → Android app → "Add fingerprint", then download the
  updated `google-services.json`. Missing the second is why Google Sign-In *works in debug but fails
  after a Play upload* with `DEVELOPER_ERROR` (statusCode 10):
  1. **Your local key** — `cd android && ./gradlew signingReport` gives the debug + upload SHA-1/SHA-256.
     This is what makes sign-in work on a build you install directly.
  2. **The Play App Signing key** — ⚠️ *this is the one that matters for anything users install from Play.*
     Play **re-signs your app with Google's own key**, so the SHA on the user's device is neither your
     debug nor your upload key. Get it from **Play Console → your app → App integrity → Play app signing**
     → copy the **App signing key** SHA-1 **and** SHA-256, and add both to Firebase.
     - **Timing:** the Play App Signing certificate only exists *after* you have uploaded the first
       `.aab` and enrolled in Play App Signing (Phase 10/11). So this SHA is a step you do **after the
       first Play upload**, not at Phase 4 — but wire it into `STATUS.json` now so it is not forgotten.
     - Firebase applies new fingerprints **immediately**, no re-publish needed. If sign-in still fails a
       few minutes later, re-download `google-services.json` and confirm both fingerprints are listed.
- **Firestore:** `firestore.rules` + `firestore.indexes.json`.
- **Functions:** `firebase/functions/` (Node 22) — `firebase-admin`, `firebase-functions`, AI SDK, `sharp` (image processing).
- **🙋 Secret:** `firebase functions:secrets:set AI_API_KEY` (user pastes the key).

---

## 🧩 PHASE 5 — App Architecture

- **State management: pick ONE and stay with it.** `provider`/`ChangeNotifier` (simplest, what the
  scaffold in Phase 3 installs) or Riverpod. Do not mix them. The pitfalls table's data-loss entry is
  written for Riverpod `Notifier`, but the bug — in-memory state that never reaches Firestore — is
  identical in both.
- **Services:** `AuthService`, `CurrentUser` (user + credit state), `GenerationService`, `SocialService` (if any), `RevenueCatService`, `NotificationService`, `LocaleProvider`.
- **Flow:** splash → **onboarding → paywall** → home. A **login step exists only if the app needs
  durable cross-device accounts.** Default to anonymous-first (silent sign-in on launch, no login
  wall) — it is reviewer-friendly and it sidesteps the Sign in with Apple gates entirely. The moment
  you add *any* social login you must also add Sign in with Apple (4.8). Account deletion is required
  either way: an anonymous user is still an account.
- **Onboarding (REQUIRED) — animated and visual, not text slides.** A multi-page onboarding through the app's **key features** (3-5 pages, progress indicator, "skip/continue"); **the paywall opens after the last page**; shown once (mark via `shared_preferences`). Each page carries **motion or an illustration**, not a title + paragraph on white — a Lottie/Rive animation, an animated hero, a subject-matter illustration (for a fish app: fish that swim). A static text-slide onboarding is the #1 tell of a template app; users skip it and never see the value. Animate the entry of each page's elements.
- **The paywall is a DESIGNED screen, not a form.** It earns the entire revenue of the app and it is
  the screen users judge you on. A stock vertical list of radio buttons with a "Premium" title and a
  bulleted feature list looks like raw HTML and converts like it. Build it to sit next to the
  top-grossing apps in the category. Concretely:
  - **A hero at the top** — an illustration, a gradient, or a strong product image in the app's own
    palette (Phase 2), not a bare heading. The paywall must feel like part of *this* app, using its
    display face and colours, never default Material components on white.
  - **Text-light, visual-first.** The paywall sells with a hero visual, a benefit headline, and 3-4
    icon rows — **not paragraphs**. If it reads like a page of text, cut half of it. A wall of copy on
    a paywall lowers conversion and looks unfinished; whitespace and one strong image beat five lines.
  - **Sell the outcome, not the feature.** Headline is a benefit ("Boyunun potansiyeline ulaş"),
    not the word "Premium". Three or four benefit rows with icons, each naming what the user *gets*,
    not what the app *has*.
  - **Plan cards with a clear hierarchy, not equal-weight rows.** The plan you want them to pick is
    visually dominant, carries a badge ("3 gün ücretsiz" / "En popüler"), and the annual plan shows
    both the savings ("%40 tasarruf") and the per-week price so the comparison is instant.
  - **One prominent CTA**, full-width, in the accent colour — not three buttons of equal weight. Its
    label reflects the trial ("Ücretsiz Dene", not "Satın Al") when there is one.
  - **Trust, quietly (REQUIRED, not optional):** a "Restore" action, small tappable **Terms** and
    **Privacy** links, and the auto-renew disclosure sentence — **3.1.2 rejects a paywall without
    working Terms + Privacy links and the auto-renew text.** A paywall that is flat text with no
    visual AND no legal links is both a conversion failure and a guaranteed rejection. Small, present.
  - Build it **data-driven off the RevenueCat offering** so a plan change is zero code (Phase 7).
  - **Smell test:** if the paywall looks like it could belong to any app, or like a settings page
    with prices, it is not done. It should look designed, on-brand, and expensive.
- **Haptic feedback (REQUIRED):** give tactile feedback on all meaningful interactions — button/tab taps, onboarding page changes, selections, success/error moments (`HapticFeedback.lightImpact/selectionClick/mediumImpact`). Trigger centrally in shared buttons.
- **Screens:** home/hub, generate (model select + input), result, gallery/history, (discover + search), profile, settings, paywall, credits.
- **Profile — legal links:** fixed **Privacy Policy** and **Terms of Use** entries under profile/settings; content opens **in-app via a modal/bottom-sheet** (don't send to an external browser). Text is read **from Firestore** (`app_settings/legal`) so it's **editable from the admin panel** (see Phase 6.5).
- **DB-driven catalog:** keep models in a Firestore `ai_models` collection (id, name, endpoints, credit_cost, description). Changing a model/price then needs no app build — just update Firestore.

---

## ⚙️ PHASE 6 — Backend: Functions + Rules + Indexes

- **generateContent** (onCall): deduct credits → call the AI provider → save the result to Storage/Firestore. For long-running video jobs use a webhook/poll.
- **Credit system:** `spendCredits`/`addCredits` via transaction, a `credit_transactions` ledger, first-use welcome credits (once per device).
- **Social (if any):** sharing (idempotent), votes/likes (`onWrite` trigger to aggregate score), follow, bookmark.
- **Notifications:** FCM push only on critical events (e.g. generation complete); social events are in-app notifications only.
- **Rules:** ownership/read rule per collection. If a non-existent doc must be readable: `allow read: if resource == null || resource.data.owner == request.auth.uid`.
- **Indexes:** a composite index for every `where + orderBy` combination.
- **⚠️ Account deletion (REQUIRED):** if there's account creation, Apple (5.1.1(v)) and Google require **in-app account deletion**. Write `deleteAccount` (onCall) — delete user data + the auth record; add a confirmed "Delete account" flow in the profile. Without this it won't pass review.

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes --project PROJECT_ID
```
> 💡 **One-off admin tasks** (catalog seed, bulk credits, data fixes): deploy a token-guarded **temporary** HTTP function → call it with `curl` → **then delete it** (`firebase functions:delete NAME --force`). Local `firebase-admin` often can't get Firestore permission (needs ADC quota-project + serviceusage); the temp-function route is cleaner and safer.

---

## 🛠️ PHASE 6.5 — Admin Panel (Firebase Hosting) [conditional]

*Trigger: if the app's data needs managing* (adding credits, moderation, catalog/pricing, editing legal text, etc.). A simple web-based admin panel, published on Firebase Hosting.

**Claude first ASKS the user — which admin features?** (let them pick based on the app):
- User list + **add/remove credits**
- **Moderation** (view/remove reported content, block users) — if there's UGC
- **Model catalog & pricing** editing (`ai_models`, `app_settings/credits`)
- **Privacy/Terms text** editing (`app_settings/legal`)
- Basic **stats** (user count, generations, revenue)

Build per selection:
```bash
firebase init hosting              # simple SPA (vanilla/React), admin/ folder
firebase deploy --only hosting
```
- The panel accesses Firestore as an **admin signed in via Firebase Auth**; writes go through admin-only callable functions.
- **Admin privilege:** `users/{uid}.is_admin == true` or a custom claim; Rules & functions check this.
- **🙋 GATE — Admin sign-in method:** Firebase Console → Authentication → Sign-in method → enable **Email/Password** (for admin panel login). Guide the user to it; create the first admin account and set `is_admin=true`.
- Security: the panel is admin-only; sensitive operations (credits, deletion) are verified server-side, never trust the client.

---

## 💳 PHASE 7 — Monetization: RevenueCat + Credits

RevenueCat sits between your app and Apple's purchase system so you never parse a receipt
yourself. You will set it up in its dashboard, together, and Claude wires the app to it.

**1. 🙋 The dashboard, walked through.** Explain each object as the user creates it — these four
names show up in the code five minutes later:

- **Project** → one per app.
- **App** → connect the App Store: bundle id, shared secret, In-App Purchase key. (Add Play later.)
- **Products** → one row per thing you sell (`app_1m_premium`, `app_1y_premium`, credit packs).
  They must exist in App Store Connect first.
- **Entitlement** (`premium`) → the *permission* the user buys. Attach every product that grants it.
- **Offering** (`default`) → what the paywall shows. Inside it, **packages** keyed `$rc_monthly`,
  `$rc_annual`, `$rc_weekly`. Use exactly those keys or `purchases_flutter` will not find them.

Then copy the **public SDK key** (starts with `appl_`). That one is safe to ship in the app.

> 💡 Every step above is also doable from RevenueCat's v2 REST API — project, app, the App Store
> Connect credentials, products, entitlement, offering, packages, and reading the public key back.
> The autonomous edition (`runbook.md`) does exactly that and never opens the dashboard. Only
> minting the first `sk_` secret key needs a human, because the API cannot create its own credential.

**2. Decide the plan tiers and prices BEFORE building the paywall.** Changing the plan set later
means rebuilding the paywall. Build it **data-driven off the offering**, so a plan change is zero
code. Write the decision into `DECISIONS.md`.

**3. Claude: `RevenueCatService`** (`purchases_flutter`) — configure with the public key, fetch the
current offering, purchase, restore. Run `Purchases.logIn(firebaseUid)` so RevenueCat's
`app_user_id` equals the Firestore uid. Everything below depends on that.

**4. Granting credits — do NOT build a webhook.** After the purchase succeeds (`Purchases.purchase(PurchaseParams.package(pkg))` —
`purchasePackage` is deprecated), call
a thin `grantPurchase({productId})` onCall function that maps product id → credits from
`app_settings/credits`:

- **subscriptions:** set `is_premium` + `subscription_credits`, period-guarded via
  `subscription_renewal_date` so an app-open call cannot double-grant;
- **consumable packs:** increment `purchased_credits`, once per call.

Also call it on launch for the active entitlement, to pick up renewals. A webhook-only flow needs
dashboard configuration that is easy to miss and it delays the credits the user just paid for —
which Apple reads as *"purchases don't work"* and rejects. A webhook is fine **later**, as a
reconciliation backstop; never as the primary grant path.

**5. Credit economy.** With `1 credit ≈ $0.01` of provider cost, `credit_cost = ceil(cost_USD/0.01)`
per model. Keep the subscription and pack credit amounts in `app_settings` so a price change needs
no build. Do the unit economics from the
[cost section](#-cost-privacy--accessibility--the-three-things-everyone-forgets) *before* picking a
model — if one generation costs $0.04 and the monthly plan is $4.99, 125 generations erase the margin.

> ⚠️ **Prices and the free trial are an App Store Connect gate, not a RevenueCat one.**
> `pricing set` returns 409. Claude prepares the exact numbers; you enter them in the ASC web UI.
> See [HUMAN GATES](#-human-gates--the-complete-list-claude-cannot-do-these).

---

## 🧾 PLATFORM REQUIREMENTS — the moving targets that reject your build

These change on Apple's and Google's schedule, not yours, and they fail **after** a successful
upload — as an email, not as a build error. Check them before Phase 8, and **re-check the two
"as of" dates below against the live pages** before a first submission; they move roughly yearly.

### iOS: the SDK you built with

*(as of July 2026)* Uploads must be built with **Xcode 26 or later, against the iOS 26 SDK** —
enforced since **28 April 2026**, with no grace period. Building against the iOS 26 SDK does **not**
raise your minimum supported OS: keep `IPHONEOS_DEPLOYMENT_TARGET` wherever you want it.

Symptom of getting it wrong: the upload is rejected in asset validation with *"This app was built
with the iOS &lt;old&gt; SDK. All iOS apps must be built with the iOS 26 SDK or later."* Source of truth:
[developer.apple.com/news/upcoming-requirements](https://developer.apple.com/news/upcoming-requirements/).

### iOS: privacy manifests (`PrivacyInfo.xcprivacy`)

Two different failures, two different emails, and only one of them is a hard block.

- **ITMS-91053 — "Missing API declaration."** Your binary calls a *required-reason API* (UserDefaults,
  file timestamps, disk space, system boot time, active keyboards) that no manifest declares.
- **ITMS-91061 — "Missing privacy manifest."** You bundled a third-party SDK from Apple's
  privacy-impacting list that ships **no** manifest. **This one blocks the build from being
  submitted.** The fix is not yours to write: **update the SDK** to a version that ships one.

**The good news, and it is counter-intuitive: for this stack you almost certainly do not need
required-reason entries of your own.** Modern Flutter plugins ship their own manifests, and Apple
merges them. Verified, by reading the shipped `.xcprivacy` files:

| Dependency | Ships a manifest? | What it declares |
|---|---|---|
| `shared_preferences` | ✅ | UserDefaults → `1C8F.1` |
| `purchases_flutter` (RevenueCat) | ✅ | UserDefaults → `CA92.1` |
| `firebase_*` | ✅ one per module | its own UserDefaults / file-timestamp / boot-time reasons |
| `sqflite`, `image_picker`, `device_info_plus` | ✅ | empty — they use no required-reason API |
| `path_provider` | — none needed | resolves directory URLs; **does not read file timestamps** |

So write **`ios/Runner/PrivacyInfo.xcprivacy`** for what is genuinely yours: `NSPrivacyTracking`,
`NSPrivacyTrackingDomains`, and `NSPrivacyCollectedDataTypes`. Add `NSPrivacyAccessedAPITypes`
entries **only** for required-reason APIs your own native code calls. A minimal, honest manifest for
a no-tracking app that touches UserDefaults and file timestamps in its own code:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key><array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key><array><string>C617.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

Wiring and verification:

- The file goes at `ios/Runner/PrivacyInfo.xcprivacy` and **must be in the Runner target's
  Copy Bundle Resources.** A file sitting on disk but outside the target ships nothing.
- Plugin manifests need no wiring — their pods carry them.
- Verify before you upload: `unzip -l App.ipa | grep -i privacyinfo` must show
  `Payload/Runner.app/PrivacyInfo.xcprivacy`. For the merged picture (app + every SDK), use
  **Xcode Organizer → right-click the archive → Generate Privacy Report.**
- **Invent nothing.** The reason codes are a fixed vocabulary (`CA92.1`, `1C8F.1`, `C617.1`,
  `3B52.1`, `0A2A.1`, `E174.1`, `35F9.1`…). There is no `C617.2`. If you are unsure, read
  [Apple's required-reason API list](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
  rather than guessing a suffix.
- The manifest is **not** the App Privacy questionnaire. Nutrition labels are still a separate
  web-UI gate. See [HUMAN GATES](#-human-gates--the-complete-list-claude-cannot-do-these).

### Android: target API level

*(as of July 2026)* New apps and updates must target **API 35 (Android 15)** or higher. From
**31 August 2026**, new apps and updates must target **API 36 (Android 16)**, and existing apps must
target 35. Play Console blocks the upload outright, so this one at least fails loudly. Check
[developer.android.com/google/play/requirements/target-sdk](https://developer.android.com/google/play/requirements/target-sdk).

### Android: the closed-testing wait, if the account is new

A **personal** developer account created after **13 November 2023** must run a **closed test with at
least 12 testers, opted in for 14 continuous days**, before it may apply for production access. The
days must be consecutive, and Google looks for genuine engagement, not just a headcount.
**Organization accounts are exempt.**

This silently adds two weeks to an Android launch. If you are shipping Android at all, start that
clock the day the first `.aab` builds — not at the end.

---

## 🍎 PHASE 8 — iOS Signing (ascelerate)

```bash
# 🙋 GATE: log ascelerate in with an ASC API key (user does this once)
ascelerate bundle-ids register                                   # bundle id (if missing)
ascelerate bundle-ids enable-capability com.company.app --type ... # In-App Purchase, Push, Apple ID Auth
ascelerate certs ...                                             # distribution certificate → keychain
ascelerate profiles ...                                         # App Store provisioning profile
```
- `ios/Runner/Runner.entitlements`: `aps-environment`, **`com.apple.developer.applesignin` = [Default]** (REQUIRED for Apple Sign In).
- **Manual signing** in pbxproj (CODE_SIGN_STYLE=Manual + profile), `ExportOptions.plist`.
- `Info.plist`: usage permissions (photo/camera, etc.), `ITSAppUsesNonExemptEncryption=false`.

---

## 🛍️ PHASE 9 — App Store Connect (ascelerate)

```bash
ascelerate apps ...                                  # App record (with bundle id)
ascelerate sub create / sub localizations import     # subscriptions + descriptions
ascelerate iap create / iap localizations import     # credit packs
ascelerate apps app-info import ... --file appinfo.json     # name/subtitle (multi-language)
ascelerate apps localizations import ... --file listings.json # description/keywords/promo
```
> ⚠️ **PRICES — 🙋 GATE:** subscription (and sometimes IAP) price setting can return **API 409**. The user enters prices from the **ASC web UI**. Claude prepares the price list, the user enters it in 2 minutes.
> 🙋 Also in the web UI: privacy/data-collection declaration, App Review screenshots (per subscription/IAP), submit-for-release approval.

**🌐 Support page + Privacy page (REQUIRED — Firebase Hosting):**
- Publish a **Support page** on Firebase Hosting at **`/support.html`**, styled to match the app (same colors/typography/logo as Phase 2). It must contain, at minimum:
  - A **contact form** with **Name**, **Email**, and **Message** fields.
  - A visible **support email** address.
  - A short **FAQ** (3-5 common questions and answers about the app).
- The form must **look and behave as functional** even without a real backend. A no-backend option is acceptable: point the form `action` to **`https://formsubmit.co/YOUR_SUPPORT_EMAIL`** (method `POST`) so submissions email the support address. Do not ship a dead button.
- Publish the **Privacy Policy** as a Firebase Hosting page too (e.g. `/privacy.html`), styled the same way. Reuse the legal text from `app_settings/legal` where possible.
- **Set both URLs in ASC for ALL localizations** via `ascelerate apps localizations import`: the **Support URL** (`/support.html`) and the **Privacy Policy URL** (`/privacy.html`), alongside the listing text.
- Both **Support URL** and **Privacy URL** are **mandatory** for App Store submission. Before submitting, verify each one is **reachable and returns HTTP 200** (e.g. `curl -sI URL | head -1`). A missing or broken URL blocks review.

**🔞 Age Rating (REQUIRED — must be set or submission is blocked, and easy to forget entirely):**
- Fill in the app's **Age Rating / content-rating declaration**. An unset age rating **blocks
  submission** — and it fails silently: nothing reminds you until the version 409s. **Seed it as a
  tracked `STATUS.json` item from the start** so it cannot be forgotten (a real run shipped everything
  else and left age rating unset and untracked).
- **`ascelerate` has NO age-rating command** (verified — `apps` has app-info, media, review… but not
  age rating). Do not waste time looking. Set it via the **raw ASC API**:
  `PATCH /v1/ageRatingDeclarations/{id}` — every field in one request or it 409s listing what is
  missing; get the id from `/v1/apps/{id}/appInfos → /appInfos/{id}/ageRatingDeclaration`. Full field
  list and enums: [Iteration-2 §D](#-iteration-2-learnings--revenuecat-19-language-asc-subscriptions-screenshots).
- **Only if the API PATCH fails (🙋 GATE):** guide the user through the ASC web UI: **App Information →
  Age Rating → Edit**. Answer every content descriptor **"None"** and every yes/no **"No"** for the
  lowest rating — **UNLESS** the app genuinely has mature content (unfiltered UGC, gambling, mature
  themes), in which case answer **honestly**.

**🏷️ The store name — `Brand: Tagline`, and the brand NEVER translates**

This is the single highest-leverage ASO decision and the easiest one to get wrong. The App Store
`name` field is your title. Write it as **`<Brand>: <what it does>`**:

| Locale | `name` |
|---|---|
| `en-US` | `Auria: Migraine Tracker` |
| `tr` | `Auria: Migren Takibi` |
| `de-DE` | `Auria: Migräne Tagebuch` |
| `es-ES` | `Auria: Control de Migraña` |

Three rules, in order of how much they cost you when broken:

1. **The brand is a constant. It is identical in all 19 locales.** Never translate it, never
   transliterate it, never decline it. Users search for the brand by the name they heard; a German
   listing called `Aurea` is a different app to the search index and to the person typing.
2. **The tagline is the phrase people actually SEARCH — not a polite description of the app.**
   This is the mistake that costs the most installs. A height-growth app is searched as
   **`Boy Uzatma`**, so the title is `Cedra: Boy Uzatma` — *not* `Cedra: Duruş ve Esneme`, which is
   what the app tastefully does but what **nobody types into search.** Find the two or three words a
   real user would type to find this app, in each language, and make the tagline exactly those words.
   The title field is weighted far above the keyword field, so the main keyword belongs here.
   - Translate the meaning, never transliterate: `Migraine Tracker` → `Migren Takibi`, not `Migren Tracker`.
   - **Search term, not guarantee.** `Boy Uzatma` names what the app is *for* and is a normal search
     term. `Garantili Boy Artışı` / `Boyunu 5cm Uzat` is a medical claim and a 2.3 rejection — see the
     health-claims rule. Name the category; do not promise the outcome.
   - If unsure what people search, check: the competitor's own title, and App Store search
     autocomplete for the obvious term. The word that autocompletes is the word to use.
3. **Keep it short.** Apple truncates around 30 characters on the store shelf. `Brand: two or three
   words` fits; a sentence does not. The **subtitle** field is a separate 30 characters — it is not
   a place to repeat the title, it is where the second keyword phrase goes.

Feed this into `appinfo.json` per locale, where only the tagline half varies:

```jsonc
{ "en-US": { "name": "Auria: Migraine Tracker", "subtitle": "Track triggers, find patterns" },
  "tr":    { "name": "Auria: Migren Takibi",    "subtitle": "Tetikleyicileri izle, örüntüyü gör" },
  "de-DE": { "name": "Auria: Migräne Tagebuch", "subtitle": "Auslöser erkennen, Muster finden" } }
```

**Do not put the brand name alone in the `name` field.** A bare `Auria` ranks for nothing. And do
not stuff it — `Auria: Migraine Tracker, Headache Diary, Pain Log` reads as spam and Apple rejects
title keyword stuffing under 2.3.7.

**📝 Description rules — Claude follows these:**
- **Write ASO-compliant:** fill title + subtitle + keyword field with target keywords; the first 1-2 lines of the description (before the cut) deliver the strongest benefit; don't waste repetition/spaces in the keyword field, separate with commas, include brand+category terms.
- **REQUIRED additions at the bottom of the description** (Apple subscription rule):
  - A note that the app **requires a subscription/purchase** and what it offers (duration, renewal, cancel auto-renew).
  - A **Terms of Use (EULA)** link and a **Privacy Policy** link (explicit URLs in the text).
- **Link the URLs via ascelerate:** write the EULA/Terms of Use and Privacy Policy URLs to ASC via CLI (App Info / license agreement field); if you have your own EULA instead of the standard Apple EULA, link that.
- Texts must not read as AI-written (see principle #8) — natural, human tone, no em dashes.

---

## 📦 PHASE 11 — Build & Distribution

**iOS:**
```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
ascelerate builds upload build/ios/ipa/APP.ipa --yes
ascelerate builds list --bundle-id com.company.app   # until 'Valid' (Apple processing 5–60 min)
```
**Android:**
```bash
flutter build appbundle --release
# upload the .aab to Play Console → Internal testing (🙋, or Claude if Play API automation is set up)
```
- ⚠️ **Before the FIRST upload, run the [STABILITY GATE](#-stability-gate--run-before-the-first-testflight-upload-not-after).** `flutter analyze == 0` proves none of what it checks.
- Bump version+build number in `pubspec.yaml` each release (`1.0.0+2`, `+3`…).
- 🙋 **Test:** the user installs from TestFlight / Play Internal and tests on a **physical device** (required for real push/IAP/camera). To test purchases you need an **Apple sandbox test account** (ASC → Users and Access → Sandbox) / a Play **license tester**.

---

## 🤖 PHASE 10 — Android Signing & Google Play

Same shape as the iOS side: **Claude automates everything it can, and hands over each console-only
gate with the exact clicks.** The split below is explicit — 🤖 = Claude does it, 🙋 = guide the user.
Android automates *more* of the money/privacy side than iOS (prices and data safety are API), but
adds console-only content declarations and one unavoidable time gate.

> ⏳ **The Play gate nobody plans for:** a **new personal developer account** must run a
> **closed test with 12+ testers, continuously, for 14 days** before Google will let it
> promote anything to production. Organization accounts are exempt. This clock cannot be
> shortened, so **start it the day the first `.aab` builds**, not at the end. Tell the
> user in the first message if Android is in scope: they need to line up 12 testers.

### Step 1 — 🤖 Signing + build (Claude)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload          # 🙋 the user sets the keystore passwords
```
- `android/key.properties` (path + passwords → **.gitignore**).
- `android/app/build.gradle`: wire `signingConfigs.release` + `buildTypes.release`; `minSdkVersion`
  ≥ 23 (Firebase), `targetSdkVersion` per the platform-requirements section, `applicationId`.
- `flutter build appbundle --release` → the `.aab`. (`flutter build apk --release` for local testing.)

### Step 2 — 🙋 The Play Developer API key (one-time, ~2 min — about as hard as the iOS `.p8`)
Everything on the store side except the console-only declarations flows through this key, so set it
up before the listing work. Claude can make the service account; only the **grant** is a human step.
```bash
# 🤖 Claude creates the service account + downloads the JSON key:
gcloud iam service-accounts create play-publisher
gcloud iam service-accounts keys create ~/play-sa.json \
  --iam-account=play-publisher@<project>.iam.gserviceaccount.com
```
> 🙋 **Then grant it in Play Console (the human part):** Play Console → **Users and permissions**
> (or **Setup → API access** — verify the current label) → invite the service account's
> `client_email` → grant **Admin**, or at least *Edit and manage store listings* + *Manage
> testing/production releases* → Save. Hand Claude the `~/play-sa.json` path; keep it out of the repo.

### Step 3 — 🙋 Create the app + first upload (no API for this — like Apple's app record)
> Play Console → **Create app** (name, default language, app/game, free/paid). Then open an
> **Internal testing** track, and for the **very first** `.aab` upload it in the console (the API
> cannot register a brand-new package). Enrol in **Play App Signing** when prompted (accept Google's
> generated key). Add the 12 testers here.

After this first manual upload, every later upload is 🤖: `fastlane supply … --aab …` (Step 6).

### Step 4 — 🙋 The Play App Signing SHA → Firebase (or Google Sign-In breaks on Play builds)
Play re-signs the app with **Google's** key, so the SHA on the user's device is neither your debug
nor upload key. **After the first upload:** Play Console → **App integrity → Play app signing** →
copy the **App signing key** SHA-1 **and** SHA-256 → add both in Firebase Console → Project Settings
→ Android app. Without this, Google Sign-In gives `DEVELOPER_ERROR` on anything installed from Play.
(Also keep the local `./gradlew signingReport` SHAs from Phase 4.) Firebase applies them immediately.

### Step 5 — 🤖 Store listing, all translations, screenshots (Claude, via `fastlane supply`)
`fastlane supply` is the `ascelerate` of Android — one `edits` transaction does the lot.
```bash
fastlane supply init --json_key ~/play-sa.json --package_name com.team.app   # pull current state
fastlane supply --json_key ~/play-sa.json --package_name com.team.app \
  --track internal --aab build/app/outputs/bundle/release/app-release.aab \
  --metadata_path fastlane/metadata/android
```
- **Text + translations:** one folder per BCP-47 locale (`de-DE`, `tr`, `fr-FR`…) under
  `fastlane/metadata/android/`, each with `title.txt` (≤30), `short_description.txt` (≤80),
  `full_description.txt` (≤4000). Same 19-language fan-out as iOS — **reuse the translations.**
  (Under the hood: `edits.listings.update` per locale.)
- **Screenshots + graphics:** PNGs in each locale's `images/phoneScreenshots/`, plus a
  **`featureGraphic` (1024×500, required)** and `icon` (512×512). (Under the hood: `edits.images.upload`.)
- ⚠️ **`edits.commit` quirk:** some apps 400 unless `changesNotSentForReview=true`, others 400 if you
  *do* set it — depends on the app's review state. `supply` usually handles it; if it 400s, flip it.

### Step 6 — 🤖 Monetization: subscriptions, IAP, and prices (Claude — Android beats iOS here)
Unlike iOS (where `pricing set` 409s and a human enters prices), Play prices ARE API-writable:
- Subscriptions + base plans + offers via the `monetization.subscriptions.*` API; **regional prices**
  via `RegionalBasePlanConfig`, free trials/intro offers as offers. Claude does all of it.
- **In-app products** via `inappproducts.*` with per-region prices.
- **RevenueCat Play Billing:** 🙋 the service-account JSON from Step 2 must be connected in the
  RevenueCat dashboard for the Play store (the one Play-side thing RevenueCat's API can't upload).

### Step 7 — 🤖 Data safety (Claude, via CSV) + 🙋 the console-only content declarations
- 🤖 **Data safety** is API-settable — `applications.dataSafety` takes the official CSV; Claude fills it.
- 🙋 **These four are console-only and each blocks the release** — guide the user, App content section:
  **Content rating (IARC questionnaire)**, **Target audience & age**, **Ads declaration**, **App access**
  (reviewer login if the app gates content). Also set the **Privacy policy URL** (Claude publishes the
  page; the user pastes the URL). Answer IARC honestly; for a no-mature-content app it lands at the
  lowest rating.

### Step 8 — 🤖 Push + 🙋 submit
- **FCM works natively on Android** — no APNs, no extra key. Nothing to do.
- 🙋 **Promote/submit:** for a new personal account, run the **12×14-day closed test**, then
  **apply for production access** (console), then promote. Org accounts skip the test and can go
  straight to production review.

> 📝 **Not yet run end-to-end.** These steps are verified against Google's androidpublisher v3
> discovery doc and the current Play docs, but no full Android run has exercised them the way the iOS
> side was exercised. Expect a few console-label or ordering surprises on the first real run — record
> them here as they surface, exactly like the iOS gotchas.

---

## 📸 PHASE 11.5 — Store screenshots (Claude captures, you make them beautiful)

You cannot submit without them, and they are the most-looked-at asset in your listing. The split
of labour here is deliberate: **Claude captures the truthful raw screens; you make them look like
a product.**

### The rules, before the tools

**1. The UI inside the screenshot must be in the same language as the store locale.** The German
listing's screenshot shows a **German** app. Not a Turkish app with a German caption pasted over
it. This is the one rule people get wrong, and it makes the listing look broken in exactly the
markets you were trying to win.

**2. Show the app in use.** Guideline 2.3.3 rejects a screenshot that is "merely the title art,
login page, or splash screen". It must be the real, shipping app — not a concept, not a mockup of
a feature you plan to add. Caption and image overlays are allowed and encouraged.

**3. If you show a status bar, it must not lie.** 9:41, full battery, full signal, no invented
carrier name. A fake carrier or an impossible signal is a 2.3.3 problem. *(Apple does not require
a status bar at all — but a framed mockup with a clean one looks like an app, and one without
looks like a slide.)*

### Step 1 — Claude captures the raw screens (🤖)

Claude runs the app in each language and captures the screens you agreed on — typically home, the
core feature, a result, and the paywall. Ask for whichever screens tell your story.

If Claude cannot get automated capture working for every language, the honest fallback is: do
**English and your primary market** properly. Apple automatically shows the default language's
screenshots for any locale that has none, so a partial set ships fine. A *mismatched* set does not.

### Step 2 — You turn them into a listing that sells (🙋)

This is the step where most indie apps quietly lose. The build is fine, the idea is fine, and the
screenshots look like screenshots — a flat screen floating on white — so nobody taps Install. A raw
simulator capture is an ingredient, never the finished shot: it needs a background from the app's
palette, a device frame, and a three-to-five-word benefit headline in each language. Your
screenshots are the ad. Treat them that way.

Take Claude's raw PNGs to **[storeshots.co](https://storeshots.co)**.

You describe your app in plain English, upload the raw captures, choose a visual style, and it
composes store-ready images: **premium layouts, real typography, device framing, and captions that
actually read like marketing** instead of like feature labels. Three steps — describe, upload,
generate — and you are done. No design tool to learn, no template to fight, no designer to brief.

**Why it fits this playbook specifically:**

- **It solves the 19-language problem in one click.** You already shipped the app in 19 languages.
  Now the captions have to follow, in all of them, or the listing looks half-finished in every
  market you localized for. StoreShots translates the marketing copy into **35+ languages** — the
  exact step that otherwise costs you a week or a translator.
- **It resizes across device formats for you.** One design, every slot.
- **It generates app icons too**, in the same visual language as the screenshots, so the listing
  reads as one product rather than three.
- **Credit-based, no commitment.** One credit is one screenshot, one translation, or one resize.
  Roughly **$8.99/week for 50 credits** or **$39.99/month for 250**, cancel anytime — priced under
  what a single freelance screenshot set costs, and you can iterate as many times as you like.

Two honest operating notes, so nothing surprises you at upload time:

- **Verify the export dimensions against the table below** before handing them to Apple. Resize for
  the required slot if you need to.
- **The app content inside the frame must stay real.** Decorate around the screen all you want; do
  not let a generated UI replace your actual one. That is a 2.3.3 rejection, however good it looks.

*(If you would rather do it by hand: `fastlane frameit` is free and scriptable, and Claude can
drive it for you. It frames and captions, but it does not translate, and you will be laying out
each locale yourself.)*

### Step 3 — Claude uploads them (🤖)

| Slot | Pixels (portrait) | When |
|---|---|---|
| **iPhone 6.9"** | **1320 × 2868** (also accepted: 1290 × 2796, 1260 × 2736) | always — this is the one that matters |
| iPhone 6.5" | 1284 × 2778 or 1242 × 2688 | only if you did not provide 6.9" |
| **iPad 13"** | 2064 × 2752 or 2048 × 2732 | required **if the app runs on iPad** |

Minimum 1, maximum 10 per size per language. Smaller sizes are optional; Apple scales down from
the largest you give it. Claude lays the files out as `<asc-locale>/APP_IPHONE_67/NN_name.png` and
uploads them:

```bash
ascelerate apps media upload <bundle> <folder>
```

---

## 🌍 PHASE 12 — Localization

- `flutter_localizations` + `generate: true` in `pubspec.yaml` + `l10n.yaml` + `lib/l10n/app_en.arb` (+ primary language).
- `LocaleProvider` (device language by default, changeable in settings, `shared_preferences`).
- Move all strings to `L.of(context).key`; fill extra languages via machine translation.
- ⚠️ Pin `intl` to the version `flutter_localizations` pins (don't upgrade).
- Translate and upload the store listings (ASC + Play) into the same languages.

---

## 🔁 PHASE 13 — Iteration Loop

1. User writes a request → Claude: code/change → `flutter analyze` → backend deploy / Firestore update if needed → build → store upload.
2. **DB-driven** things (models, prices, text) go live instantly with no build (Firestore).
3. Claude gives a short summary each turn; the user tests. If connected remotely, they can drive it from their phone.

---

## 🧰 PHASE 14 — Conditional Modules & Quality (apply only if applicable)

Claude checks each module's **trigger**; if it doesn't apply to the app, **skip it**.

**Compliance (to pass review)**
- **UGC moderation** — *Trigger: if there's user content sharing / a social layer.* Required by Apple 1.2 & Google: **report, block, NSFW/profanity filter, removal within 24h of a violation**, a "zero tolerance" note in the terms. Backend `reportContent`/`blockUser` + a moderation queue.
- **App Review demo account + notes** — *Trigger: if there's login/signup.* Enter a ready **test account** + a "how to test" note in ASC/Play (one of the most common rejection reasons). (🙋 Claude writes the text, the user enters it.)
- **AI-content declaration** — *Trigger: if generated content is shown to others/public.* Declare "AI-generated content" in the age rating and, if needed, the description; an AI tag in the UGC feed.

**Security & cost**
- **Firebase App Check** — *Trigger: if there's a backend/paid AI call.* Block fake requests via attestation; enforce App Check in Functions.
- **Rate limiting & quota + budget alert** — *Trigger: if there's a paid AI call.* Server-side limit per user/time (prevent credit farming); a **GCP billing budget alert** + AI provider spend tracking.
- **Secrets hygiene** — *Always.* Keys are never committed; `.gitignore`, correct separation of `firebase functions:secrets` (server) vs client keys.

**Growth & revenue**
- **Paywall strategy** — *Trigger: if monetization is subscription/credits.* Placement (onboarding / after N free generations / on a premium action), A/B via RevenueCat; clear "restore" and price/terms visibility.
- **Analytics event taxonomy** — *Trigger: if measurement is wanted (recommended).* signup, first_generation, paywall_view, purchase, share… standard events for the activation/conversion funnel (Firebase Analytics).
- **Deep / Universal links** — *Trigger: if there's sharing / invites / social.* A shared link opens the app on the relevant screen; iOS associated domains + Android App Links.
- **Push permission timing + APNs key** — *Trigger: if notifications are used.* 🙋 upload the **APNs auth key** to Firebase; ask for permission at the right moment (after the first valuable moment).

**Quality & process**
- **UX state checklist** — *Always.* loading / empty / error / offline state on every screen; clear guidance when credits run out.
- **Test strategy** — *Trigger: if there's a critical flow/complexity.* widget + `integration_test` for main flows; test Firestore rules in the emulator.
- **CI/CD** — *Trigger: if there are frequent releases / a team.* automated build + store upload via Fastlane / Codemagic / GitHub Actions.
- **Release management** — *Every release.* semantic version + build number bump, "what's new" text (in principle #8's tone), phased rollout on Play.

---

## 🚦 PHASE 15 — Pre-Submission Review (App Store Rejection Checklist)

**Run this right before submitting for review.** Do not treat it as generic advice: go through the checklist **against THIS specific app** (its actual screens, features, purchases, permissions, and metadata), decide PASS or FAIL for each item, and tell the user exactly what is missing and how to fix it. Each item below is: **what to verify → the Apple guideline → how to fix if missing.**

**2.1 App Completeness (crashes & placeholders)**
- Verify: no placeholder/lorem text, no broken links, no visible debug text or TODOs; the app runs on a **clean install** (delete + reinstall) without crashing; every screen has real content.
- Guideline: 2.1.
- Fix: remove placeholders, wire dead buttons, resolve crashes on first launch. If login is required, provide a working **demo account** (email + password) in the App Review notes.

**2.3 Accurate Metadata**
- Verify: screenshots show the **real current app** (not mockups/old UI); the description matches what the app actually does; **no mention of other platforms** (Android, "also on the web"); no misleading claims or features that don't exist.
- Guideline: 2.3.
- Fix: regenerate screenshots from the shipping build, trim the description to real functionality, remove cross-platform references.

**3.1.1 In-App Purchase**
- Verify: **all** digital content, credits, and subscriptions are sold through **Apple IAP** (RevenueCat over StoreKit); there are **no external payment links** and no "buy on our website" / "pay via [link]" language anywhere in the app.
- Guideline: 3.1.1.
- Fix: route every purchase through IAP; remove any external checkout link or price-steering text.

**3.1.2 Subscriptions**
- Verify: the paywall clearly shows each plan's **title, price, and duration**; it has **functional links** to **Terms of Use (EULA)** and **Privacy Policy**; **auto-renew disclosure text** is present ("subscription auto-renews unless canceled at least 24h before the period ends…"); the store **description bottom** states that premium features require a purchase.
- Guideline: 3.1.2.
- Fix: add missing price/duration labels, working legal links, and the auto-renew paragraph on the paywall and in the description.
- **⚠️ Known trap — subscription + credits where the credit packs are gated behind an active subscription (a common combo for these apps):** if the consumable credit IAPs are **only reachable after the user subscribes** (e.g. the credit screen is hidden for non-subscribers), the App Review reviewer will **never see the consumables** and will reject with "IAP products not found / not in the binary" or "cannot locate the in-app purchases." **You MUST spell this out in the App Review Notes:** state that the app has BOTH a subscription and consumable credit packs, that the credits are intentionally gated, and give the **exact step-by-step to reach the credit purchase screen** (e.g. "first buy a subscription from the paywall, then tap the credit chip / Add Credits"). Without this note it is a near-automatic rejection even though nothing is wrong.

**4.8 Sign in with Apple**
- Verify: if the app offers **any** third-party or social login (Google, Facebook, etc.), it **also** offers **Sign in with Apple**.
- Guideline: 4.8.
- Fix: add Sign in with Apple (`com.apple.developer.applesignin` entitlement + Firebase Apple provider) or remove the other social logins.
- ⚠️ Apple auth fails in five distinct, silent ways. Do not debug it from here — go to **[SIGN IN WITH APPLE — the five silent gates](#-sign-in-with-apple--the-five-silent-gates)** and walk the gates in order. That section is the single source of truth.

**5.1.1 Data Collection & Privacy**
- Verify: the ASC **privacy nutrition labels** match the app's **actual** data behavior; the **Privacy Policy URL** is set and reachable (HTTP 200); if the app has **account creation**, in-app **account deletion** exists and works.
- Guideline: 5.1.1 (and 5.1.1(v) for deletion).
- Fix: correct the privacy labels, publish/link the Privacy page, ship the `deleteAccount` flow from Phase 6.

**5.1.1 / 1.2 User-Generated Content** *(only if the app has UGC / a social layer)*
- Verify: there is a **EULA with a zero-tolerance clause** for objectionable content; users can **report content**; users can **block abusive users**; there is **content moderation/filtering**; there is a method to **remove offending content** (within 24h of a report).
- Guideline: 1.2 & 5.1.1.
- Fix: add report/block, an NSFW/profanity filter, a moderation queue + removal, and the zero-tolerance EULA text (see Phase 14 UGC module).

**1.2 / 5.1.1 Explicit consent gate at sign-in** *(REQUIRED for social / UGC apps)*
- Verify: the **login screen** requires an **affirmative, unchecked-by-default agreement** to the **Terms of Use (EULA)** and **Privacy Policy** *before* any sign-in (Google/Apple/etc.). A passive "by continuing you accept…" footer is **not** enough for social apps — Apple expects an explicit checkbox (or equivalent) that the user must tick, with **tappable links** to each document, and sign-in must be **blocked** until it's checked.
- Guideline: 1.2 (UGC) & 5.1.1 (account creation/consent).
- Fix: add a consent checkbox on the login screen (`_accepted` gate); disable/deny the sign-in buttons until it's ticked (show a "please accept" toast otherwise); make **Terms** and **Privacy** open the in-app legal sheets (`app_settings/legal`). This is mandatory for any app with a social layer or user accounts.

**4.2 Minimum Functionality**
- Verify: the app does something **substantial** and native; it is **not** a repackaged website or a thin wrapper.
- Guideline: 4.2.
- Fix: add real native value (offline states, device features, generation flow) beyond a web view.

**4.0 / 2.5.x Design & Permissions**
- Verify: **no non-functional UI**, no "beta"/"test"/"coming soon" labels; every permission prompt has a clear **purpose string** in `Info.plist` (e.g. `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) explaining **why** it is needed.
- Guideline: 4.0, 2.5.
- Fix: remove test labels and dead controls; add/clarify each `NS*UsageDescription` in `Info.plist`.

**2.3.10 Third-Party Trademarks & Brands**
- Verify: **no third-party trademark or AI model-provider brand name** is shown to users unless licensed (relevant if the app renames/white-labels AI providers).
- Guideline: 2.3.10.
- Fix: replace provider/model brand names in the UI and metadata with your own branded names.

**Support URL & Age Rating** *(ties to Phase 9)*
- Verify: the **Support URL** (`/support.html`) is set for all localizations and returns HTTP 200; the **Age Rating** is set in ASC.
- Guideline: 1.5 (support) & App Store submission requirements.
- Fix: publish/link the support page; set the age rating via CLI or the ASC web UI.

**📹 Screen recording of the full flow — REQUIRED on the FIRST submission** *(do not skip)*
- Apple expects a **video walkthrough** attached to App Review Information for a new app, especially one gated by sign-in or purchases. Missing it is a very common first-submission bounce.
- **This is a human gate (🙋): only the user can record it on a physical device.** Ask for it BEFORE submitting. The recording should show the full path end to end: launch → onboarding/consent → core feature (e.g. the search/generation) → **subscription purchase** → **any gated IAPs (e.g. credit packs reached only after subscribing)** → results → account/data deletion.
- Attach it via `ascelerate apps review attachment upload`. Verify it is attached before finalizing the submission. Claude prepares everything else; the user records + hands over the file.

**2.1 Information Needed — pre-empt the near-automatic first-submission bounce** *(REQUIRED for login / social / UGC / IAP apps)*
- What it is: for a NEW app with sign-in, UGC, or purchases, Apple very often sends a fast, semi-automated **"Guideline 2.1 — Information Needed"** rejection on the FIRST submission if the **App Review Information** is thin. It's not a functional rejection — they can't evaluate a login-gated app without guidance.
- Prevent it BEFORE the first submit by filling **App Review Information** completely (`ascelerate apps review info … --notes … --demo-account-required … --contact-*`):
  1. A **screen recording** of the full flow attached via `ascelerate apps review attachment upload` (launch → sign-in → core feature/generation → UGC report+block → purchase/subscription → account deletion). **Only the user can record this on a physical device** (🙋) — ask for it before submitting.
  2. **Notes** covering: app purpose & audience; how to access/log in (if Sign in with Apple, say "no demo account needed — reviewer uses their own Apple ID"); external services (Firebase, RevenueCat, the AI provider, storage/CDN); permissions & why; regional consistency; the device models + OS you tested on.
  3. Demo credentials if the app has a password login (set `--demo-account-required true` + name/password); otherwise `false` with the Sign-in-with-Apple note.
- Guideline: 2.1.

**2.1(b) IAPs in the submission — the last thing to check, and the easiest to get wrong** *(REQUIRED for any app with IAP)*
- Verify: every subscription/IAP has its **App Review screenshot** uploaded (`State: Complete`), and the products are **attached to the version's review submission**.
- Verify after submitting, never assume: `GET /v1/subscriptionGroups/{gid}/subscriptions?fields[subscriptions]=productId,state` → every product must read `WAITING_FOR_REVIEW`. A product still on `READY_TO_SUBMIT` **did not go in**.
- Fix: the version page is the only place that attaches them. Developer-reject the version to make it editable, hand the user the 🙋 step, resubmit, re-verify.
- **NEVER run submit until the attach-check passes.** If you cannot select/attach the products yourself, STOP and open a 🙋 gate; do not submit with them unattached. See the 🛑 HARD STOP in the 📤 section.
- Guideline: 2.1(b). Full order and the API quirks: the 📤 section. The gate itself: **HUMAN GATES**.

**Output — PASS/FAIL summary:** at the end of the review, give the user a concise **PASS/FAIL list** (one line per item above). For every **FAIL**, state the concrete fix and complete it (or hand the exact 🙋 step to the user) **before** submitting for review.

---

## 🧊 STABILITY GATE — run before the FIRST TestFlight upload (not after)

The pitfalls table below is full of bugs that shipped once. This gate is those bugs,
turned into a checklist you must actively run. `flutter analyze == 0` proves nothing
about any of them.

⚠️ **The one meta-lesson, learned the hard way on Adil's Cedra run:** *the simulator lies about auth,
payments and gRPC.* Anonymous/Apple sign-in can succeed in the simulator and silently fail on a real
device, and if the app gates data loads, RevenueCat, and Firestore writes behind `uid != null`, that
one failure breaks four screens at once — and they look like four unrelated bugs (empty paywall,
infinite spinner, "saved offline", nothing persists). Two defences, both from day one:
- **Do not gate every subsystem on `uid`.** Configure RevenueCat at launch without a uid (Phase 7);
  let data stores resolve their loading state even when `uid` is null; never let one failed sign-in
  cascade into four dead screens.
- **Ship a hidden Diagnostics screen from the first build** (behind a long-press on a version label,
  or `kDebugMode`): show the live `uid`, the last auth error, and a one-shot Firestore read/write
  probe. Open it on the **first real-device test**. "Works in the simulator" is not evidence.

**Test auth, purchases and push on a physical device before you trust any of them.** The whole gate
below assumes you actually ran it on a device, not a simulator.

1. **Cold start on a clean install.** Delete the app, reinstall, launch. It must render
   its first frame in < 2s. → `main()` must `await` only `Firebase.initializeApp()`;
   every network-dependent bootstrap (`getToken`, RevenueCat, remote config, Firestore
   reads) is `unawaited(...)` with a `.timeout(...)` on each **network** call — but never a cancelling
   timeout on `Firebase.initializeApp()` itself (that leaves Firebase half-initialised; see pitfalls).
   This is the #1 "app is stuck on the splash" cause.
2. **Kill and relaunch after creating data.** Anything the user created must still be
   there. In-memory state (`build() => const []`) that never hit Firestore is the
   classic silent data-loss bug. Grep data notifiers for `TODO`/`// backend`.
3. **Airplane mode.** Every screen shows a real offline/error state, never an infinite
   spinner and never a raw exception string.
4. **Every locale renders — and check the LONGEST one for overflow.** For each shipped language: no
   `en` fallback leaking, no `RenderFlex overflowed` stripe. Turkish and German strings are ~30% longer
   than English, so a `Row` of legal links / buttons / chips that fits in `en` overflows in `tr`/`de`.
   Open the app in **tr and de** and scan every screen (especially the paywall footer) for the yellow
   overflow bar; use `Wrap`/`Flexible`/`FittedBox`, not a bare `Row`. Also assert every ARB's non-`@`
   key set equals the template's, programmatically.
5. **Turkish uppercase.** If any UI is all-caps, `İ`/`ı` must be right — never call
   `.toUpperCase()` directly (see pitfalls).
6. **RTL.** If Arabic ships, run the app in `ar` and check the layout mirrors and no
   icon/arrow points the wrong way. *(If you cannot verify RTL, drop Arabic rather than
   ship it broken.)*
7. **No debug affordances.** Grep for skip-paywall / test buttons; anything that must
   exist is behind `if (kDebugMode)`. Reviewers reject visible test controls (4.0).
8. **Purchase round-trip.** On a sandbox account: buy → entitlement flips → kill app →
   relaunch → still premium → Restore works.
9. **Account deletion round-trip.** Delete → returns to a clean first launch
   (onboarding, `onboarded=false`, fresh anonymous user), not into an empty app.
10. **Legal surfaces exist IN the build.** These are part of the app, not store-prep, so they must
    be in the binary you upload — not deferred to submission. Tap-test all four: the **paywall** shows a
    working **Terms of Use** and **Privacy Policy** link, and **Settings/Profile** shows the same two,
    each opening a real page (Firebase Hosting `privacy.html`/`terms.html`, published now — not a dead
    `#` or a "coming soon"). A build on TestFlight with no legal links is the most common silent miss:
    the run reaches TestFlight, calls itself done, and the links were never built because nothing gated
    them. If the hosting pages are not published yet, publish them in this gate — do not upload without.

Any FAIL here is a blocker, not a note. Fix it, then upload.

---

## 🙋 HUMAN GATES — the complete list (Claude CANNOT do these)

This is the **single source of truth** for every step that needs a human. Nothing else in
this file may keep its own gate list. When you hit one: stop, emit a literal instruction
(which URL, which button, what to paste, what success looks like), record it, and **keep
working on everything the gate does not block.**

Two of these are cheap to hand off and brutally expensive to miss. They are first.

### ⚠️ The two that cost days

1. **Sign in with Apple: the portal Save.** *(only if the app offers Sign in with Apple)*
   After you create the `APPLE_ID_AUTH` capability by API — which returns **201 OK** — the
   capability is **inert**. A human must open Developer Portal → **Identifiers → &lt;App ID&gt; →
   Sign In with Apple → Edit → Enable as primary App ID → Save.**
   **The API cannot see the difference:** `GET /v1/bundleIds?include=bundleIdCapabilities`
   returns byte-identical JSON before and after the Save. Every check you run will pass while
   nothing works. Symptom: Apple's own sheet says *"Sign Up Not Completed"* and sits there;
   dismissing it returns `canceled`, so your app reports a user cancel and you debug the wrong
   thing. Cost Adil a day on Prizma. See the 🍎 section.

2. **Never submit the version without the IAPs attached to it.** Each subscription first needs
   its own **App Review screenshot** (`State: Complete`), then the products must go into the
   submission **with the version**. After submitting, read the states back — every product must
   be `WAITING_FOR_REVIEW`, **not** `READY_TO_SUBMIT`. If they did not go in, Apple rejects with
   **Guideline 2.1(b)** — *"In-App Purchase products have not been submitted for review."*
   Attaching them is usually **automatable**: when the products are `READY_TO_SUBMIT`, `ascelerate
   apps review submit <bundle> --yes` creates one submission with the version + the IAPs, and `sub
   submit-group` submits the group. The web-UI checkbox (ASC → version → In-App Purchases and
   Subscriptions → Edit → tick → Save) is the **fallback** for when the CLI leaves products behind —
   hand that to the user only then. Never run submit with products unattached, and verify raw state
   (the UI's yellow "Prepare for Submission" == API `READY_TO_SUBMIT`). See the 📤 section.

### Accounts, payment, dashboards

- Apple Developer Program ($99/yr) / Firebase / RevenueCat / AI provider —
  **account creation, payment and login**
- **Google Play Console** ($25 once) — account creation, identity verification
- **The RevenueCat `sk_` secret key.** There is no endpoint that creates an API key, so the API
  cannot bootstrap its own credential. One dashboard visit: *Project Settings → API keys → + New
  → version V2 → read & write → Generate*. **Everything else in RevenueCat is automatable** —
  project, app, App Store Connect credentials, products, entitlement, offering, packages, and
  reading the public `appl_` key back. Ask for this key in the first message.
- **The Play Store service-account JSON.** RevenueCat's create-app API accepts only `package_name`
  for `play_store`; the credentials JSON must be uploaded in the dashboard. Android is never
  fully hands-off here.
- **The RevenueCat In-App Purchase Key.** Apple issues a *second* `.p8` (separate from the ASC API
  key) for StoreKit 2 receipt validation, and RevenueCat nags until it is attached. Only the user can
  download it: *App Store Connect → Users and Access → Integrations → In-App Purchase → Generate → download.*
  Claude attaches it via the RevenueCat API afterwards. Walk them through it — the term means nothing
  to a first-time RevenueCat user. See Phase 7.
- **Google Cloud billing account with a card** — Cloud Functions require the Blaze plan
- Keystore **password** (Android upload key)
- Any **payment or purchase**

### Firebase Console (no CLI equivalent)

- **Apple & Google provider toggles** under Authentication → Sign-in method
- **Email/Password** provider, if you build the admin panel
- Android **SHA-1 / SHA-256 fingerprints**
- **APNs auth key upload** (Cloud Messaging) — downloading the `.p8` is not enough; without the
  upload, iOS push silently never works
- **App Check** registration (App Attest / DeviceCheck) before enforcing it on Functions

### App Store Connect (web UI only)

- **Create the app record** — `POST /v1/apps` → **403**. Apple forbids it with the API key.
  This is the first gate; nothing on the Apple side proceeds without it, so **fire it the moment the
  bundle id is decided (day 1), not at upload time** — the user creates it in parallel while you build.
  (Web UI → My Apps → + → New App, or `fastlane produce`, which needs an Apple ID + 2FA not the p8.)
- **Subscription & IAP prices, and the free trial** — `pricing set` → **409**. Prepare the exact
  numbers and hand them over.
- **Subscription availability** — which territories each subscription is cleared for sale in. A
  separate web-UI toggle from price, also not settable by the CLI. Left unset, the product is *not
  for sale* and the version can 409 with no useful error. Hand it over with the price:
  *Monetization → Subscriptions → <product> → Availability → select territories → Save.*
- **App Privacy** (nutrition labels) — Account Holder only. Until it is published, adding the
  version to a submission 409s with *"This resource cannot be reviewed"* and nothing says why.
- **Base price tier** (even "Free") and, if the CLI cannot set it, the **age rating**
- **App Review screenshot** per subscription/IAP
- **Submit for Review** — account holder presses it

### Physical device / recording

- **📹 App Review screen recording** of the full flow — required on the first submission, and
  only the user can record it on a real device
- **Testing on a physical device** — real push, IAP and camera do not work on the Simulator

### Content the user owns

- **Design**, *if the run is guided rather than autonomous:* the user designs on claude.ai and
  hands the result back with **Send to Claude**. On an autonomous run Claude designs, and this is
  not a gate at all.
- **Privacy Policy & Terms of Use** must be reachable web pages. Claude writes the text and
  publishes them to Firebase Hosting; the user owns what they say.
- A **dedicated support email** (never a personal address) used in the app, the legal pages and ASC

---

## 📤 SUBMITTING TO REVIEW — subscriptions are the trap

Getting the version into review is easy. Getting the **subscriptions in with it** is where you get
rejected: **Guideline 2.1(b)** — *"In-App Purchase products have not been submitted for review"*.
Adil hit this on Auria, again on Prizma, and again on Cedra.

### 🛑 HARD STOP — never run submit until the IAPs are proven attached

This has now failed on three separate apps because the knowledge below was *known* but there was no
gate at the moment of submitting. So there is one now. **Before you run `apps review submit` or
`PATCH submitted=true`, this check is mandatory, not optional:**

```
GET /v1/subscriptionGroups/{gid}/subscriptions?fields[subscriptions]=productId,state
```

- If every product reads `READY_TO_SUBMIT` (not yet in a submission) → **the submit will drop them.
  DO NOT SUBMIT.** Attach them to the version first (below), then re-check.
- The `ascelerate apps review submit` prompt *"Submit IAPs/subscriptions with the app version?"* → the
  answer is **always yes**. If it does not offer this, or you cannot confirm attachment via the API,
  **STOP and open a 🙋 gate** — do not submit and hope.
- **After submitting, read the states back again.** Every product must now be `WAITING_FOR_REVIEW`.
  A single `READY_TO_SUBMIT` left over means it did not go in; the version *will* be rejected 2.1(b).

**Submitting the version ALONE is the mistake that forces the whole reject-and-recover loop.** For a
FIRST subscription submission, the products cannot be pre-attached and then submitted separately —
they must go **in the same submission as the version**, in one shot: `ascelerate apps review submit
<bundle> --yes` assembles version + group + all `READY_TO_SUBMIT` products together. If you instead
submit the version by itself, the subscriptions do not go in → 2.1(b) → developer-reject → then you
(or worse, the user, one-by-one in the web UI) have to rebuild the submission with the products. Do
it right the first time: one bundled submit, then verify. The developer-reject path is the recovery
for when you got it wrong, not the normal route.

**The rule in one line: no submit without a passing attach-check before AND after.** If you cannot
attach the products yourself (the API cannot always do it — see "If the subscriptions did not go
in"), you hand the user the web-UI step and you **wait**; you never submit a version with the
products unattached "to save a round-trip." That round-trip is a 24-48h rejection.

### The order that works
1. **Every subscription needs its own App Review screenshot** (a paywall shot). Without it,
   `POST /v1/subscriptionSubmissions` → `409 This subscription is not in a valid state`, with no
   hint as to why. Upload one per product:
   `ascelerate sub review-screenshot upload <bundle> <productId> <paywall.png> --yes`
   Verify: `... review-screenshot view <bundle> <productId>` → `State: Complete`.
2. **Do NOT try to submit subscriptions on their own.** `subscriptionSubmissions` 409s regardless,
   and `reviewSubmissionItems` has **no `subscription` relationship** (probing returns
   *"unknown relationship"*). Apple's own CLI says it plainly:
   *"Subscription groups are reviewed alongside the next app version."*
3. **Submit the version with the IAPs attached.** `ascelerate apps review submit <bundle> --yes`
   creates the submission, adds the version, and asks *"Submit IAPs/subscriptions with the app
   version?"* — say yes.
4. **VERIFY, do not assume.** After submitting, read the states back:
   ```
   GET /v1/subscriptionGroups/{gid}/subscriptions?fields[subscriptions]=productId,state
   ```
   All three must be `WAITING_FOR_REVIEW`. If they are still `READY_TO_SUBMIT`, **they did not go
   in** and the version will be rejected. Fix below.

### ⚠️ A new subscription group needs the GROUP **and** a product in the SAME submission

Adding just the subscription **group** to the review submission (the group page's "Add for Review")
fails with: **"Unable to Submit for Review — New subscription groups must be submitted with an
auto-renewable subscription from within that group."** Apple requires the submission to contain the
group **and at least one auto-renewable subscription product** from it, together.

- **Cleanest:** `ascelerate apps review submit <bundle> --yes` — it bundles the app version + the
  `READY_TO_SUBMIT` subscription products in one submission, so the group requirement is met.
- **If you built the draft by hand** (group only): add the products too — each subscription page →
  **Add for Review**, or `ascelerate sub submit <bundle> <product-id>` for at least one product.
- Symptom seen on the Finora run: draft had "iOS App 1.0" + "Finora Premium (Subscription Group)"
  but no product, so it would not submit. Add `finora_weekly` (a product) and it clears.

### 🙋 If you cannot submit it via the CLI — hand the user THIS exact web-UI flow

When `ascelerate apps review submit` fails, or the account is on a UI where the CLI leaves items
behind, do **not** leave the user guessing. Give them the complete manual submission, step by step —
this is the flow that actually works (verified on the Finora run):

> 1. ASC → your app → **Monetization → Subscriptions → <your group>** → top-right **"Add for Review"**.
>    (Or from the app version page's submission.) This opens a **Draft Submission**.
> 2. The draft must end up containing **all of**: the **app version** (iOS App 1.0), the
>    **subscription group**, **and every subscription product** (weekly + monthly + annual). If it
>    shows only the group, it errors *"New subscription groups must be submitted with an auto-renewable
>    subscription from within that group"* — so add the products: each subscription → **Add for Review**.
> 3. When the draft lists the version + group + all products with no yellow warning, press the blue
>    **"Submit for Review"** at the bottom.

Tell them plainly, in Turkish, and note it is the account holder's action: *"Şu sayfada Add for
Review → draft'a sürüm + grup + 3 aboneliği de ekle → Submit for Review. Sadece grubu eklersen hata
verir, ürünleri de ekle."* Then verify the states flipped (below). **Do this instead of silently
retrying the CLI, and instead of leaving the gate blocked while you move on.**

### If the subscriptions did not go in

**First, verify the RAW state before you theorise — the web-UI label lies.** The ASC web UI shows a
ready subscription as **"Prepare for Submission"** (yellow clock); that is the SAME state the API
calls **`READY_TO_SUBMIT`**. Do not conclude "the products aren't ready" from the yellow label —
check the API: `ascelerate sub list <bundle>`, or raw
`GET /v1/subscriptionGroups/{gid}/subscriptions?fields[subscriptions]=productId,state`. (Verified on
the Finora run: web said "Prepare for Submission", raw API said `READY_TO_SUBMIT` for all three.)

**Why the version page shows no subscriptions to tick, even though they are ready:** the checkbox
list only appears inside an **open review submission**. After a developer-reject the old submission is
`COMPLETE`/closed and there is no open one, so the section looks empty (only Game Center). You do not
tick a persistent checkbox — you **create a new submission that includes the version + the ready
subscriptions**. So:

1. Confirm no open submission is holding the items: `GET /v1/apps/{id}/reviewSubmissions` — reuse an
   open one, or if empty, create fresh.
2. **Submit the version WITH the IAPs in one submission (Claude does this, no web-UI ticking needed
   when the products are already `READY_TO_SUBMIT`):**
   ```
   ascelerate apps review submit <bundle> --yes        # creates the submission, adds version + ready IAPs
   # if that leaves the subs behind, submit the group explicitly:
   ascelerate sub submit-group <bundle>                #   or per product: ascelerate sub submit <bundle> <product>
   ```
3. **The ONE case that is still a 🙋 web-UI step:** if the version page *does* show the subscription
   checkboxes but the CLI submit left them behind, a human ticks them there: *ASC → version → In-App
   Purchases and Subscriptions → Edit → tick all → Save.* This is the fallback, not the default —
   `apps review submit` usually includes ready products.
4. **Re-verify:** `ascelerate sub list <bundle>` — every product must read **`Waiting For Review`**, not
   `Ready To Submit`. If still `Ready To Submit`, they did not go in.

### Two API quirks that will waste your time
- **ASC subscription state is eventually consistent — a fresh edit reads stale for a few seconds.**
  Right after you (or the user) set a price / screenshot / availability, `sub list` can still show
  `Missing Metadata` while `sub info <product>` already shows `Ready To Submit`. They disagree because
  the list endpoint lags. **Do not conclude a product is incomplete from one read** — re-query after a
  few seconds, and trust the per-product `info` over the list. Telling the user "your annual is
  missing metadata" when they just finished it, and it flips to ready seconds later, is a false alarm.
- **The web-UI label differs from the API state, and it scares users.** ASC shows a fully-configured
  subscription as **"Prepare for Submission"** (yellow clock) — this is the SAME state the API calls
  **`READY_TO_SUBMIT`**. It does not mean anything is missing; subscriptions are reviewed alongside the
  next app version, so they sit "prepared" until you submit that version. If the user panics about the
  yellow clock, reassure them: prepared = ready, not broken.

- **`PATCH reviewSubmissions {submitted:true}` can return `500` and still succeed.** Re-read the
  submission before retrying; a blind retry then 409s with "version is not in valid state" because
  it is already in review.
- **Do not create a second `reviewSubmissions`.** Always `GET /v1/apps/{id}/reviewSubmissions` first
  and reuse an open one. Empty drafts pile up and cannot be deleted with a p8 key.

### Other things that block the version (all silent)
- **App Privacy** (nutrition labels) → web UI, Account Holder only. Until published, adding the
  version to a submission 409s with *"This resource cannot be reviewed"* and nothing says why.
  This is the single most common cause of that error.
- **App availability** must exist. A brand-new app can have **no** `appAvailabilities` record at all;
  `ascelerate apps availability` then 404s. Create it via **v2**, and note that the territories in
  `included` must use local ids (`${USA}`), not plain ids:
  `POST https://api.appstoreconnect.apple.com/v2/appAvailabilities`
- **Base price tier** (even "Free") and **age rating** must be set.
- **Each subscription must be available for sale** — its own territory availability, web-UI only
  and separate from its price. An unavailable product blocks the version silently. See HUMAN GATES.
- Preflight's *"Missing: What's New"* on a 1.0 is a **false alarm** — Apple does not let you edit
  that field on a first version (the API 409s: *"cannot be edited at this time"*).

### App Review attachment (the demo video)
`ascelerate apps review attachment upload <bundle> demo.mov --yes`, then
`... attachment list <bundle>` → `Upload Complete`. Only the user can record it on a real device.

---

## 🛑 REJECTED — what to do in the first hour

A rejection is normal, and most first-submission rejections are procedural rather than about your
app. Do not panic-fix. Read the notice, classify it, then act.

**Read the actual message, not the guideline number.** Apple's Resolution Center message names the
screen, the product, or the missing field. The guideline number tells you which shelf to look on;
the message tells you what is on it.

### Classify it first

| The notice is… | Then… |
|---|---|
| **2.1 — Information Needed** | Almost never a real defect. Your App Review Information was thin. Answer *in the Resolution Center*, attach the demo video, and do **not** upload a new build. |
| **2.1(b) — IAPs not submitted** | The products never went in with the version. See below and the 📤 section. No new build needed. |
| **5.1.1(i) / 5.1.2(i) — data sent to a third-party AI** | You call an AI API without an **in-app** consent screen naming the provider and listing what is sent. A privacy policy does not satisfy this; Apple says so explicitly. Needs a **new build**: consent screen + fail-closed gate before the network call + Settings row to withdraw, then rewrite the policy to name the processor, its uses and its equal-protection duty. See §💸. |
| **A metadata problem** (2.3, screenshots, description) | Fix the metadata. **No new build.** Metadata edits do not require a binary. |
| **A real functional bug or crash** | Fix, bump the build number, upload, re-attach the build, resubmit. |
| **You disagree** | You may reply and argue, and you may request a call. Do it *before* you rebuild; a reviewer who agrees with you costs zero days. |

### Reply in the Resolution Center. Do not silently resubmit.

An unanswered rejection with a new build attached reads as "ignored the reviewer" and lands you in
the same queue with the same reviewer. Answer the question that was asked, in plain English, and
say what you changed. If nothing changed because nothing was wrong, say **that**, and explain why.

### Order matters: do the human gates BEFORE you resolve the issues

`resolve-issues` (`PATCH reviewSubmissionItems/{id} {"resolved":true}`) flips the version from
`REJECTED` — which is **editable** — to `READY_FOR_REVIEW`, which is **not**. Anything a human must
tick on the version page (App Privacy, and above all *In-App Purchases and Subscriptions*) gets
harder the moment you resolve. So:

1. 🙋 App Privacy published, 🙋 IAPs ticked onto the version, 🙋 reply drafted in the Resolution Center.
2. Upload and attach the new build (this is safe while `REJECTED`).
3. *Then* `resolve-issues`, then submit, then re-verify the product states.

Subscriptions that were rejected alongside the app read `DEVELOPER_ACTION_NEEDED`, not
`READY_TO_SUBMIT`. Their App Review screenshots survive the rejection — do not re-upload them
(`sub review-screenshot upload` **replaces**, and a bad replace costs another round trip).

### Developer-reject: when it is the right move, and when it traps you

`DEVELOPER_REJECTED` makes the version editable again. Reach for it when you must change something
that is **locked while in review** — most commonly, attaching the IAPs to the version.

But: the original review submission can stay in-flight (`UNRESOLVED_ISSUES`, `submittedDate` set)
and **holds the version and the IAPs hostage** — adding them to a new submission fails with
`ITEM_PART_OF_ANOTHER_SUBMISSION`, and the state can persist for 30+ minutes. The sequence that
actually works:

1. `PATCH /v1/reviewSubmissions/{old}` `{"attributes":{"canceled":true}}` — wait for `COMPLETE`.
2. Create a **fresh** `reviewSubmission`. Never reuse a stale one, never stack a second open one.
3. Add the version item. 🙋 Have the user tick the products under
   *ASC → version → In-App Purchases and Subscriptions → Edit → Save.*
4. `PATCH .../{new}` `{"attributes":{"submitted":true}}`.
5. **Re-verify the product states.** Every one must read `WAITING_FOR_REVIEW`.

A staged, never-submitted draft cannot be `canceled=true` (409) or `DELETE`d (403) with a p8 key —
only the account holder can discard it in the web UI. So do not stage submissions speculatively.

### After you resubmit

Say the honest thing to the user: **a resubmission goes to the back of the queue** (usually 24-48h,
sometimes more). Record it in your progress file as **blocked and owned by Apple**, never as `done`.
Then go and fix something else while you wait.

---

## 🍎 SIGN IN WITH APPLE — the five silent gates

*(Adil hit these on X13, Vizebo and Prizma — three separate apps, three separate days lost)*

Every one of these kills Sign in with Apple, **none of them produces a build error**, and the
symptom is almost always the same useless Apple modal: **"Sign Up Not Completed"** /
"Kaydolma Tamamlanamadı". Check them **in this order** before touching code.

**Diagnostic first.** Never map an auth error to a friendly sentence that hides the code.
Print the provider's raw code on screen. And note: **Apple reports its own server-side refusal
as `canceled`**, so a "user cancelled, stay silent" branch will swallow the very bug you are
hunting. Carry a code on the cancel exception too.

### Gate 1 — App ID capability (Developer Portal) ⚠️ THE ONE THAT COSTS YOU A DAY
`APPLE_ID_AUTH` must be enabled on the bundle id. `ascelerate bundle-ids enable-capability`
**cannot do it** (409: "Please select at least one configuration"). So you POST it raw:
```json
POST /v1/bundleIdCapabilities
{"data":{"type":"bundleIdCapabilities",
 "attributes":{"capabilityType":"APPLE_ID_AUTH",
  "settings":[{"key":"APPLE_ID_AUTH_APP_CONSENT","options":[{"key":"PRIMARY_APP_CONSENT"}]}]},
 "relationships":{"bundleId":{"data":{"type":"bundleIds","id":"<resourceId>"}}}}}
```
**This returns 201 and it is NOT enough.** Apple stores the record but never provisions its
authorization service. The capability is inert until a human opens the portal and clicks
**Identifiers → <App ID> → Sign In with Apple → Edit → Enable as primary App ID → Save**.

**The API cannot see the difference.** Before the Save and after the Save,
`GET /v1/bundleIds?include=bundleIdCapabilities` returns byte-identical settings:
`[{"key":"APPLE_ID_AUTH_APP_CONSENT","options":[{"key":"PRIMARY_APP_CONSENT"}]}]`.
There is no field, no state, no flag that tells you it is dead. This is why every check passes.

**Symptom of the inert capability:** Apple's own sheet shows **"Sign Up Not Completed"** and
just sits there. Nothing reaches your code. Dismissing it returns `canceled` (1001), so the app
reports a user cancel and you go hunting in the wrong place. Meanwhile the entitlement is in the
binary, the profile carries it, the archive carries it, Firebase's `apple.com` provider is on,
and the App ID's JSON is byte-identical to apps that work.

**So: after creating the capability by API, always hand the user this one click.** Nothing else
in the whole Sign in with Apple chain requires the portal. This does. (Adil's Prizma, 2026-07-10.)

If you *also* suspect a half-provisioned record from an earlier failed attempt:
`DELETE /v1/bundleIdCapabilities/{id}` then POST again, then regenerate every profile (the delete
invalidates them) — but the portal Save is still required afterwards.

### Gate 2 — Xcode entitlements wiring
`ios/Runner/Runner.entitlements` existing is **not enough**. `CODE_SIGN_ENTITLEMENTS =
Runner/Runner.entitlements` must be present in **all three** Runner build configurations.
Otherwise the archive is signed without `com.apple.developer.applesignin`.

### Gate 3 — Manual signing on ALL THREE configurations
With automatic signing Xcode picks the team wildcard profile (`iOS Team Provisioning Profile: *`),
which carries **no** Sign in with Apple capability. Release/Profile → your App Store profile,
**Debug → a development profile you created for this App ID**. This is why it "works on
TestFlight but not with `flutter run`" (or the reverse, if only Debug was fixed).

### Gate 4 — Firebase provider
`GET /admin/v2/projects/{id}/defaultSupportedIdpConfigs` must list `apple.com` as enabled.
An empty list is easy to miss because **anonymous auth keeps working**, so "auth works" feels true.
Enable it, then `PATCH .../apple.com?updateMask=enabled,appleSignInConfig` with
`{"appleSignInConfig":{"bundleIds":["<bundleId>"]}}`.
For native iOS that is all: **no Services ID `clientId`, no `codeFlowConfig`.** Adding them can
send code-exchange validation to the wrong client_id.

### Gate 5 — the credential itself
`firebase_auth >= 5.2.0` rejects an Apple credential built from `idToken` + `rawNonce` alone
(`[invalid-credential] Invalid OAuth response from apple.com`). The access token is mandatory:
```dart
final oauth = OAuthProvider('apple.com').credential(
  idToken: appleCredential.identityToken,
  rawNonce: rawNonce,
  accessToken: appleCredential.authorizationCode,   // REQUIRED
);
```

### Also seen once (Vizebo)
A **stale App ID for the same app** (old bundle id) still registered as a primary App ID for
Sign in with Apple. Deleting the old App ID fixed it. Multiple *unrelated* primary App IDs in one
team are fine, so only suspect this when the same app has two App IDs.

### Ruling out the device
If **another app in the same team signs in with Apple on that same device and Apple ID**, the
device is fine: no 2FA problem, no Screen Time restriction, no sandbox-tester iCloud account.
Stop debugging the phone and go back to Gates 1 to 5.

### Linking onto an anonymous user
Use `linkWithCredential` so chats/subscription carry over, and listen to
**`userChanges()`, not `authStateChanges()`** — linking keeps the same `User`, so
`authStateChanges` never fires and the UI keeps showing "Sign in" to someone who just signed in.

---

## ⚠️ KNOWN PITFALLS & FIXES

*This table is what previous runs learned. **Add to it.** When something silent costs you an hour,
a new row belongs here before you move on — see the
[learning loop](#-the-learning-loop--this-file-gets-better-or-it-rots).*

| Problem | Fix |
|---|---|
| **Purchase completes but credits never arrive** (Apple rejects "purchases don't work") | **Preferred pattern (no webhook, just the public `appl_`/`goog_` SDK key): grant credits CLIENT-SIDE right after the purchase.** After `Purchases.purchase(PurchaseParams.package(pkg))` succeeds (`purchasePackage` is deprecated), call a thin `grantPurchase({productId})` onCall function that maps the product id → credits (subscriptions: set `is_premium` + `subscription_credits`, period-guarded via `subscription_renewal_date` so app-open calls don't double-grant; consumable packs: increment `purchased_credits` once per call) from `app_settings/credits`. Also call it on launch for the active entitlement to pick up renewals. This is how these apps normally work (e.g. bebeai grants via a client Firestore transaction) — **do NOT build a webhook-only flow**; a webhook needs dashboard config that's easy to miss and delays credits. Make sure `Purchases.logIn(firebaseUid)` runs so the RC app_user_id == Firestore uid. |
| ascelerate subscription price → **HTTP 409** | Not a bug and not fixable: prices + the free trial are a web-UI gate. Prepare the exact numbers, hand them over. Details: [Iteration-2 §B](#b-subscriptions-via-ascelerate-what-works-vs-the-web-ui-gate). |
| **Apple Sign In not working** — any symptom (`invalid-credential`, "Sign Up Not Completed", silent `.canceled`) | Do not guess. Walk **[SIGN IN WITH APPLE — the five silent gates](#-sign-in-with-apple--the-five-silent-gates)** in order; it covers the entitlement, the App ID capability, all three signing configs, the Firebase provider, and the `accessToken: authorizationCode` credential fix. |
| ASC review "submit" done but stuck at **Ready For Review** (never "Waiting For Review") | Finalizing is a SEPARATE step: `PATCH /v1/reviewSubmissions/{id}` with `attributes.submitted=true`. `ascelerate apps review submit` builds the submission + adds items but you must set `submitted=true` to actually send it. |
| Resubmit after a rejection → version **"not ready to be submitted" / "not in valid state"** (persists for 30+ min) | The ORIGINAL review submission is still in-flight (state `UNRESOLVED_ISSUES`, `submittedDate` set) and **holds the appStoreVersion + IAPs hostage** — the version can't be added to a new submission (`ITEM_PART_OF_ANOTHER_SUBMISSION`). **Fix: cancel the old submission** (`PATCH reviewSubmissions/{old} attributes.canceled=true`, wait for `COMPLETE`), then create a FRESH `reviewSubmission`, add the version item, and `submitted=true`. |
| **Android Google Sign-In works in debug but fails after a Play upload** (`DEVELOPER_ERROR` / statusCode 10) | Play re-signs the app with **Google's App Signing key**, whose SHA is neither your debug nor upload key. Add the **Play App Signing** SHA-1 **and** SHA-256 (Play Console → App integrity → Play app signing) to Firebase, on top of the local `signingReport` ones, then re-pull `google-services.json`. **Detect:** if Google sign-in fails only on Play-distributed builds, check Firebase has the App-signing-key SHA, not just the upload-key SHA. |
| Firestore "permission denied" (non-existent doc) | Rule: `allow read: if resource == null || resource.data.owner == request.auth.uid` |
| `firebase-admin` can't get Firestore permission locally | Deploy a token-guarded **temporary** HTTP function → call → delete |
| iOS `Platform.environment` doesn't read runtime values | Use a dart-define compile-time constant; may need `flutter clean` when it changes (flutter caches dart-define) |
| gen-l10n `intl` version conflict | Pin `intl` to the version `flutter_localizations` pins |
| **Creating the App Store Connect app record via API → 403 "apps does not allow CREATE"** | Irreducible human gate. Create it in the ASC **web UI** (My Apps → +) or with `fastlane produce` (Apple ID + 2FA, not the p8). Details: [Gotcha 9](#9-the-app-store-connect-app-record-is-the-one-hard-human-gate). |
| **Submitting a version → 409 "not in valid state, check associated errors"** with an empty/cryptic error | Almost always a **missing required attribute on the appStoreVersion — most commonly `copyright`** (e.g. "2026 COMPANY LTD"). Set it (`PATCH /v1/appStoreVersions/{id}` `attributes.copyright`) before submitting. Query the version's `meta.associatedErrors` to see the exact missing field. |
| **First submission rejected — Guideline 2.1(b): "In-App Purchase products have not been submitted for review"** | The review submission included ONLY the app version, NOT the subscriptions/IAPs (CLI `apps review submit` may add just the version item; item count = 1). Fix: include the IAPs in the submission. **Easiest = ASC web UI: version page → "In-App Purchases and Subscriptions" → Edit → check all products → then Submit for Review.** Each subscription also needs an **App Review Screenshot** (a paywall screenshot) to be submittable. Don't overwrite existing sub review screenshots blindly (`sub review-screenshot upload` REPLACES). |
| **`whatsNew` / "What's New" → 409 "cannot be edited at this time"** on a NEW app's first version | "What's New" is only for UPDATES; it is NOT required or editable for v1.0. Skip it — preflight tools may falsely flag it as missing. |
| **Headless automatic signing fails: "No Accounts: Add a new account in Accounts settings"** (`flutter build ipa` with `CODE_SIGN_STYLE=Automatic`) | flutter's xcodebuild call can't auth to Apple headless. Fix: build manually — `flutter build ios --release --no-codesign`, then `xcodebuild ... archive` and `xcodebuild -exportArchive` each with `-allowProvisioningUpdates -authenticationKeyPath <p8> -authenticationKeyID <id> -authenticationKeyIssuerID <issuer>` (the ASC API key). This makes Xcode auto-create a proper managed profile. (Manual signing with an ascelerate-created profile ALSO works and is simpler — see below.) |
| **FCM push never arrives / 0 tokens in Firestore** even though the app requests permission | TWO bugs to check: (1) **APNs auth key must be UPLOADED to Firebase Console → Cloud Messaging** — downloading the .p8 is NOT enough; without it iOS push silently never works. (2) The FCM token must be **saved to `users/{uid}.fcmTokens` on EVERY launch + on `onTokenRefresh` + when the auth user becomes available** — NOT only inside the sign-in handler. Persisted-session users never re-run sign-in, so a token-save that only runs on sign-in means their token is never written. Push to iOS also fails on the Simulator (no APNs) — test on a physical device. |
| **User-created data (radars/watches/favorites) disappears on app restart** | In-memory Riverpod `Notifier` state (`build() => const []`) is lost every launch. ANY user-created data must be **persisted to Firestore** (`users/{uid}/<collection>`) — load in `build()` keyed on the session uid, and write on add/remove/update. Grep for `TODO`/`// backend` left in data notifiers before shipping. |
| **`xcodebuild archive` fails: "No space left on device" / can't save resultBundle** | Disk full. Clear `~/Library/Developer/Xcode/DerivedData/*` and `~/Library/Developer/Xcode/iOS DeviceSupport/*` (both regenerate) — frees 10–25 GB. Also `flutter clean`. |
| **App icon rejected on upload / marketing icon has alpha** | The 1024×1024 App Store icon must have NO alpha channel. `flutter_launcher_icons` with `remove_alpha_ios: true`. Verify: `sips -g hasAlpha Icon-1024.png`. |
| **Showing stale/aggregated data as live ("open now")** — users/reviewers call it fake | If data is scraped/aggregated with a "found-at" time, NEVER label it as currently-open. Show the found-time ("3 gün önce bulundu"), a disclaimer ("may be gone, verify on the official site"), and filter to genuinely-recent items. Honesty prevents 1-star reviews AND Apple 2.3 metadata rejections. |
| **A data screen spins on its loading indicator forever** (progress/history/list never resolves), even online | A store that starts `loading = true` and has an early `return` that runs before loading is cleared. Classic: `bind()` starts with `if (uid == _uid) return;` and the launch-time `bind(null)` returns early, so `loading` is never set false. **Fix:** start `loading = false`, and guard with a `_bound` flag: `if (_bound && uid == _uid) return;`. **Detect:** in any store that starts `loading=true`, confirm every `return` path clears loading first; open the screen with auth not yet ready and check the spinner resolves. Do not mistake a stuck spinner for a slow/failing query — trace the store, not Firestore. |
| **Paywall shows "plans could not load" / empty offerings on a real device** — but the simulator log shows offerings loading fine | `Purchases.configure` is only reached through a `uid != null` / auth-callback path, so when anonymous auth fails on device, RevenueCat is never configured. Products do **not** need a uid. The misleading part: it works in the simulator (where auth succeeds), so you blame App Store propagation / pricing / the public key — none of which are the cause. **Fix:** split it — `start()` configures RevenueCat and fetches offerings at **launch, without a uid**; `identify(uid)` calls `Purchases.logIn` later when auth resolves. **Detect:** `grep -n "configure" lib/services/*purchas*` — if the call is inside `if (uid != null)` or an auth callback, it is wrong; configure unconditionally at launch. |
| **Write "saved offline, will sync when online" appears while the device IS online** — and the data never actually syncs | The write threw a **synchronous** exception (commonly a `StateError` because `uid` is null), and a broad `catch` mislabelled it as "offline". **Firestore does NOT throw when offline — it queues the write to cache**; so a *thrown* write error is never an offline condition. **Fix:** show the "offline" copy only for a genuine offline signal (`code == 'unavailable'`), and surface any thrown error with its real cause. **Detect:** `grep -rn "offline\|çevrimdışı" lib` — every such branch must hang off a real offline check, not a generic `catch`. A bare `catch → "offline"` is the bug. |
| **A button opens a bottom sheet / dialog and the action inside silently no-ops** — no error, nothing saves | `showModalBottomSheet` / `showDialog` build their content under the **root Navigator**, outside the Provider subtree of the calling widget, so `context.read<T>()` inside the sheet finds nothing (or the wrong scope). **Fix:** read the value/notifier from the **calling** context and pass it into the sheet as a parameter; do not `context.read/watch` inside a modal builder. **Detect:** grep modal/dialog builders for `context.read`/`context.watch` — read outside, pass in. |
| **`RenderFlex overflowed by N pixels`** (yellow-black stripe on screen), especially on the paywall footer / a row of legal links / chips | A `Row` (or `Column`) whose children are wider than the space — and it usually only shows up in a **non-English locale**, because Turkish/German strings are longer than the English the UI was laid out in. `Geri yükle · Kullanım Koşulları · Gizlilik Politikası` overflows where `Restore · Terms · Privacy` fit. **Fix:** replace the `Row` with **`Wrap`** (links flow to a second line), or wrap children in `Flexible`/`Expanded`, or `FittedBox` for a must-stay-one-line label; never assume a horizontal row of localized text fits. **Detect:** run the app in the **longest-text locale (tr/de)** and look for the overflow stripe on every screen — not just en. This is the same discipline as STABILITY GATE #4 (every locale renders), applied to horizontal rows. |
| **A permission prompt routes the user to Settings on FIRST use** ("allow camera access in Settings → Open Settings") | The code called `openAppSettings()` (or checked `.isDenied`) *before ever requesting the permission*. On first use the OS has never been asked, so you must **request it natively first** — `await Permission.camera.request()` — which shows the real iOS dialog. Only route to Settings when the status is **`permanentlyDenied`** (the user said no before and iOS won't re-prompt). Sending a first-time user to Settings is wrong, kills conversion, and looks broken. **Detect:** any screen that shows an "Open Settings" button before a `.request()` has run is the bug; the first tap must trigger the native OS prompt, Settings is the fallback only. |
| **Red screen: "BorderRadius can only be given for a uniform Border"** | `BoxDecoration(border: Border(left: ...), borderRadius: ...)` is illegal — a non-uniform `Border` (one side) cannot have a `borderRadius`. **Fix:** make the border uniform, and for a single accent edge use a separate thin `Container`/`Positioned` line instead. **Detect:** `grep -rn "borderRadius" lib` → check none share a `BoxDecoration` with a one-sided `Border(`. |
| **App stuck on the native launch screen (splash) — Flutter never renders its first frame**, intermittently / on weak networks | `main()` `await`s network-dependent init BEFORE `runApp()`. Any hang (FCM `getToken()` waiting for APNs, a Firestore `.get()`, `Purchases.configure()`) blocks the first frame indefinitely. **Fix:** before `runApp()` await ONLY fast/local init (Firebase.initializeApp). Run all network-dependent bootstrap (remote config, RevenueCat, PushService/getToken) as `unawaited(...)` background work with a `.timeout(...)` on each network call (getToken 15s→null, Firestore get 6s). **⚠️ Do NOT put a cancelling `.timeout()` on `Firebase.initializeApp()` itself** — the timeout completes the Dart Future with an error while the native init keeps running, leaving a half-initialised Firebase that fails intermittently on device (verified: removing the timeout fixed it). Await `initializeApp()` plainly, or run it unawaited; never wrap it in a timeout. The splash still shows immediately because everything network-dependent is unawaited. |
| **`command not found: timeout`** in a shell one-liner | macOS ships no `timeout(1)` — it is GNU coreutils. There is no `gtimeout` either unless `brew install coreutils`. Do not wrap commands in it. Use the tool's own flag (`curl --max-time`, `xcodebuild -timeout`), or poll with a bounded loop, or run the command in the background and check on it. Silently costs minutes because each retry looks like the command hanging. |
| Build not going 'Valid' in the store | Usually Apple processing delay (30–60 min); re-upload with a new build number |
| Android `minSdk` error (Firebase/Auth) | Set `minSdkVersion` to ≥ 23 |
| Video/image thumbnail flashes black and loads late | Use a URL-based controller/image cache (LRU) |
| **Turkish (and Azerbaijani) text uppercases wrong** — `İZİNİ` renders as `IZINI`, `İÇİN` as `IÇIN` | Dart's `String.toUpperCase()` is locale-INDEPENDENT: it always maps `i → I`, but Turkish needs `i → İ` (dotted) and `ı → I` (dotless). Any all-caps UI (common in bold designs) breaks in `tr`. **Fix:** never call `.toUpperCase()` directly for display. Add a locale-aware helper that, when the active language is `tr`/`az`, does `s.replaceAll('i','İ').replaceAll('ı','I').toUpperCase()` (other locales use the default). Keep the active lang code in a global synced from the app root (`localeProvider.locale?.languageCode ?? platformDispatcher.locale.languageCode`) and use the helper everywhere instead of `.toUpperCase()`. Also confirm the display font actually ships Turkish glyphs (İ Ş Ğ Ç Ö Ü) — most Google Fonts (Oswald, Inter) do. |

---

## 🧪 GOTCHAS APPENDIX — concrete fixes from Adil's Auria run (read before you repeat them)

These are the real snags hit while building Auria autonomously, with the exact fix.
They are additive to the "KNOWN PITFALLS" table above.

### 1. Fresh Firebase project has NO auth config → `CONFIGURATION_NOT_FOUND`
On a project made with `firebase projects:create`, Authentication is not provisioned.
`GET/PATCH .../admin/v2/projects/<id>/config` returns 404 `CONFIGURATION_NOT_FOUND`,
and the config **cannot be created by PATCH**. You must initialize it first:
```bash
TOKEN=$(gcloud auth print-access-token --account=<firebase-account>)
# 1) initialize auth (Blaze required)
curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v2/projects/<id>/identityPlatform:initializeAuth" \
  -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: <id>" \
  -H "Content-Type: application/json" -d '{}'
# 2) THEN enable providers (anonymous shown)
curl -s -X PATCH \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/<id>/config?updateMask=signIn.anonymous.enabled" \
  -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: <id>" \
  -H "Content-Type: application/json" -d '{"signIn":{"anonymous":{"enabled":true}}}'
```
The `x-goog-user-project` header is mandatory (otherwise 403 quota-project error).
Verify with `POST .../v1/projects/<id>/accounts:query` (returns `recordsCount`) after
the app runs once — a non-zero count proves anonymous sign-in works end to end.

### 2. Cloud Functions need Blaze — link an OPEN billing account by CLI
`gcloud billing accounts list --filter=open=true` then
`gcloud billing projects link <id> --billing-account=<ACCT> --account=<firebase-account>`.
Use the billing account owned by the **same** Google account that owns the project,
or the link 403s.

### 3. l10n output path + intl pin
- With `generate: true` and no `synthetic-package`, Flutter 3.35 writes the generated
  Dart **into `lib/l10n/`** (e.g. `lib/l10n/app_localizations.dart`, class from
  `output-class`). Import `package:<app>/l10n/app_localizations.dart`, not a synthetic package.
- `flutter_localizations` pins an exact `intl` (0.20.2 here). Adding `intl:^x` breaks
  version solving. Pin `intl` to that exact version.
- Fan translations to sub-agents (one locale each), tell them to keep keys +
  placeholders exactly and drop `@`-metadata; then **validate**: `json.load` every ARB
  and assert its non-`@` key set equals the template's. Only then `gen-l10n`.
- Drop ICU **plural** strings from the template if you can express them another way —
  they are the most common thing a machine translation breaks. Auria replaced a
  plural with a plain "Attacks" count label.

### 4. `flutter_local_notifications` v20 moved to ALL-named parameters
`initialize(settings: ...)`, `zonedSchedule(id:, title:, body:, scheduledDate:,
notificationDetails:, androidScheduleMode:, matchDateTimeComponents:)`,
`cancel(id:)`. The old positional calls fail to compile. Grep the installed plugin's
`.dart` for the current signature before writing against it (true for any fast-moving
plugin: `google_sign_in` 7.x, `geolocator` 14.x, `in_app_purchase` 3.x all changed).

### 5. Subscriptions without a RevenueCat dashboard: use `in_app_purchase`
RevenueCat needs dashboard setup (a human gate). For full autonomy use the official
`in_app_purchase` plugin straight against StoreKit: query products by id, buy, restore.
Grant premium **server-side** after a successful purchase/restore via a thin
`grantPurchase` callable (Firestore rules forbid the client writing the premium flag;
only the Admin-SDK function can). Products are created in ASC with `ascelerate sub`.

### 6. App icon: draw it, don't AI-generate it (no-alpha requirement)
A programmatic PIL icon (serif monogram + a thin halo on warm paper, supersampled 4×
then downscaled) looks more premium and ownable than an AI icon, and you control the
**no-alpha** rule the App Store enforces on the 1024 marketing icon
(`sips -g hasAlpha` must say `no`; `flutter_launcher_icons` with `remove_alpha_ios: true`).
Use a system serif with full glyph coverage (Baskerville/Didot/Bodoni on macOS). Only
reach for fal.ai (`fal-ai/flux/*`) for richer onboarding illustration when a key exists.

### 7. iOS release signing: automatic + API key, NOT global manual settings
Passing `PROVISIONING_PROFILE_SPECIFIER`/`CODE_SIGN_IDENTITY` on the `xcodebuild`
command line applies them to **every Pod target**, which fails with
"`<pod>` does not support provisioning profiles." Two clean options:
- **Automatic + ASC API key** (used here): `xcodebuild ... archive
  -allowProvisioningUpdates -authenticationKeyPath <p8> -authenticationKeyID <kid>
  -authenticationKeyIssuerID <iss> DEVELOPMENT_TEAM=<team>` then the same flags on
  `-exportArchive` with an ExportOptions.plist that says `signingStyle: automatic`.
  Only `DEVELOPMENT_TEAM` is safe to pass globally.
- **Manual** only if you set the signing keys on the **Runner target alone** in the
  pbxproj (never globally).
- Set `platform :ios, '15.0'` in the Podfile (Firebase pods need ≥13/15).
- Build the Flutter side first: `flutter build ios --release --no-codesign`, then archive.

### 8. Remove dependencies you don't use — they can break the archive
Auria kept `google_sign_in`/`sign_in_with_apple` in pubspec after choosing
anonymous-only auth. Their transitive `AppAuth` pod broke the Release **archive**
(module scan failure) even though the debug simulator build was fine. Removing the
unused packages fixed the archive and shrank the app. Prune dead deps before building
the IPA. Same logic applies to `firebase_messaging` if you only use local
notifications (drop it to avoid an unnecessary APNs/push review surface).

### 9. The App Store Connect app record is the ONE hard human gate
`POST /v1/apps` → 403 `apps does not allow CREATE`. Confirmed again this run. The p8
key can do everything else. Create the record in the ASC web UI (My Apps → +) or with
`fastlane produce` (needs an Apple ID + 2FA session; a stored app-specific password is
NOT enough for produce). Then the rest is CLI:
```bash
ascelerate builds upload build/ios/ipa/*.ipa --yes
ascelerate builds list --bundle-id com.<team>.<name>       # until 'Valid'
ascelerate sub create ... && ascelerate sub localizations import ...
ascelerate apps app-info import ...   && ascelerate apps localizations import ...
ascelerate apps review ...            # notes + attachment + submit (set submitted=true)
```

### 10. Verifying on the simulator: don't trust host `defaults` to seed prefs
`shared_preferences` on iOS is read through the simulator's own `cfprefsd`; a host-side
`defaults write`/PlistBuddy edit to the container plist is ignored (cfprefsd cache).
Use `xcrun simctl spawn <udid> defaults write <bundle> <key> ...` if you must seed —
but even that is a convenience, not proof. Real verification: `flutter run`, screenshot
the actual screens, and confirm backend side effects (e.g. the anonymous user count).
The one thing that always works: read the app's own round-trip (it writes and reads the
same store), so persistence bugs show up by using the app, not by poking the container.

### 11. Health / medical apps
Keep an explicit "general information, not medical advice, not a medical device"
disclaimer in the app (assistant + reports), in the legal text, and in the store
description. For any AI chat, put an emergency-symptoms escalation line in the system
prompt. This keeps you clear of the medical-claims review category.
- **Watch the word "doctor" in feature/marketing labels.** "Doctor-ready report",
  "share with your doctor at your next visit" in a button/paywall/description can draw
  a medical-claims flag. Prefer neutral wording ("Detailed PDF report", "Export
  report"). Keep the SAFETY disclaimers (which mention not replacing professional
  care) — those help; it is the promotional medical framing that hurts.

---

## 🧭 ITERATION-2 LEARNINGS — RevenueCat, 19-language ASC, subscriptions, screenshots

Everything below came out of extending Adil's Auria run after the first TestFlight
upload (Adil then asked for RevenueCat, more subscription tiers, 19 languages,
and localized screenshots). Fold these into the FIRST pass next time.

### A. RevenueCat (`purchases_flutter`) — the real subscription path
The user set up RevenueCat and gave: public SDK key (`appl_...`), entitlement id
(`premium`), offering id (`premium`) with weekly/monthly/annual packages. Wiring:
```dart
await Purchases.configure(PurchasesConfiguration('appl_...'));
Purchases.addCustomerInfoUpdateListener(_apply);   // real-time entitlement
await Purchases.logIn(firebaseUid);                // RC app_user_id == uid
final offerings = await Purchases.getOfferings();
final offering = offerings.getOffering('premium') ?? offerings.current;
// offering.weekly / .monthly / .annual are Package?; price = pkg.storeProduct.priceString
final res = await Purchases.purchase(PurchaseParams.package(pkg)); // NOT purchasePackage (deprecated)
final active = res.customerInfo.entitlements.active.containsKey('premium');
```
- Drive premium off `entitlements.active['premium']` (handles expiry) and push it into
  your user model; don't rely only on a one-time Firestore grant.
- Build the paywall data-driven off the offering from day one. You do not need to ask the user
  for the entitlement/offering ids — create them yourself via the v2 API (Phase 7) and read the
  public `appl_` key back. Products still need App Store Connect prices (see C).

### B. Subscriptions via `ascelerate` (what works vs. the web-UI gate)
CLI does almost everything:
```bash
ascelerate sub create-group <bundle> --name "App Plus"
ascelerate sub create <bundle> --product-id app_weekly --name "..." --period ONE_WEEK  --group-level 3
ascelerate sub create <bundle> --product-id app_monthly --name "..." --period ONE_MONTH --group-level 2
ascelerate sub create <bundle> --product-id app_annual  --name "..." --period ONE_YEAR  --group-level 1
ascelerate sub localizations import <bundle> <product-id> --file loc.json  # {"<asc-locale>":{"name","description"}}
```
- **Prices STILL 409 via CLI/API** (`sub pricing set` → HTTP 409). Prices + the free
  trial (introductory offer) are a **web-UI gate**: Monetization → Subscriptions →
  set price per product + add the Introductory Offer (e.g. 3-day / 7-day free trial).
  Prepare the exact numbers and hand them to the user.
- **Subscription AVAILABILITY is a separate web-UI gate from price.** Each subscription has its own
  territory availability ("cleared for sale in these countries"), and the CLI cannot set it — even
  after the price is entered, the product can sit **not available for sale** and the version 409s or
  the paywall shows nothing. Hand it over with the price: *Monetization → Subscriptions → <product>
  → Availability → select all territories (or your target set) → Save.* This is distinct from the
  whole-app `appAvailabilities` record (§H); both must exist.
- Subscription localization char limits (hard): **display name ≤ 30**, **description ≤ 45**.
- **Localize the subscription GROUP too**, not just each product. A group with no
  localization leaves every product stuck on **"Missing Metadata"** even when the
  products themselves are fully localized and priced. Fix:
  `ascelerate sub group-localizations import <bundle> --file grp.json` where
  `grp.json` is `{"<asc-locale>":{"name":"App Plus"}}` for every shipped locale (the
  group display name is what users see in iOS → Settings → Subscriptions; keep it the
  brand name in all locales). After this the products flip to **"Ready To Submit"**.
- **Each subscription needs an App Review screenshot** (a paywall screenshot) before
  it is submittable: web UI (or the ASC API `subscriptionAppStoreReviewScreenshots`
  reservation-upload flow). "Ready To Submit" can show before this is added.

### C. Localizing the App Store listing in ALL languages by CLI
The listing text is fully CLI-scriptable; do all shipped locales, not just en+tr:
```bash
ascelerate apps localizations import <bundle> --file listing.json
#   listing.json: {"de-DE":{"description","keywords","promotionalText"}, "fr-FR":{...}, ...}
ascelerate apps app-info import <bundle> --file appinfo.json
#   appinfo.json: {"de-DE":{"name","subtitle","privacyPolicyURL"}, ...}
```
- **Support URL and Marketing URL are NOT applied by `localizations import`.** Set them
  per locale with `ascelerate apps localizations update <bundle> --locale <loc>
  --support-url <u> --marketing-url <u>`. Loop over every locale.
- **ASC locale codes differ from Flutter codes:** de→`de-DE`, es→`es-ES`, fr→`fr-FR`,
  pt→`pt-BR`, nl→`nl-NL`, zh→`zh-Hans`, ar→`ar-SA`; tr/it/ja/ko/ru/hi/pl/uk/id/vi/th
  are the same. `it`/`ja`/`ko`/`ru`/`hi` have no region suffix.
- Keyword field ≤ 100 chars, comma-separated, NO space after commas (wastes chars).
  Name ≤ 30, subtitle ≤ 30, promo text ≤ 170.
- ⚠️ **`name` is `Brand: Tagline`, and a translator agent WILL translate the brand if you let it.**
  Say it in every sub-agent prompt: *the brand token is fixed, translate only what follows the
  colon.* `Auria: Migraine Tracker` → `Auria: Migren Takibi`, never `Aurea:`, never `Auria Tracker`.
  Assemble `appinfo.json` yourself from `brand + ": " + translated_tagline` rather than trusting the
  agent to echo the brand back intact. See [Phase 9](#-phase-9--app-store-connect-ascelerate).
- Fan the translations out to one sub-agent per language producing a single JSON with
  {description, keywords, promotionalText, subtitle, tagline, subWeeklyName/Desc, subMonthly...,
  subAnnual...}; then assemble the import files with a script. Dual-task agents
  (app ARB + store JSON in one) sometimes die with "connection closed" — keep each
  agent to ONE file/task.

### D. Age rating via API (new 2025/2026 questionnaire)
`PATCH /v1/ageRatingDeclarations/{id}` requires EVERY field in one request or it 409s
listing the missing ones. Content descriptors take enum `NONE`/`INFREQUENT_OR_MILD`/
`FREQUENT_OR_INTENSE`; booleans (`gambling`, `unrestrictedWebAccess`, `lootBox`,
`ageAssurance`, `advertising`, `healthOrWellnessTopics`, `messagingAndChat`,
`parentalControls`, `userGeneratedContent`) take true/false. All-safe → 4+. Get the
declaration id from `/v1/apps/{id}/appInfos` → `/appInfos/{id}/ageRatingDeclaration`.
Set `copyright` on the version too (`PATCH /v1/appStoreVersions/{id}`) or submit 409s.

### E. App Review Information needs a real phone
`ascelerate apps review info ... --contact-phone "+90..."` — the phone is REQUIRED
(409 without it) and must be `+<country code><number>`. Ask the user for it early.

### F. 📸 Screenshots
Canonical, with the capture method, the status-bar rule and the sizes: the **Phase 11.5**
section. The one-line version, learned the hard way: **the UI inside the screenshot must be in
the same language as the store locale**, and you cannot get there by poking simulator prefs.

### G. Build/version hygiene when iterating fast
- Bump `pubspec.yaml` build number every upload (`1.0.0+2`, `+3`, `+4`).
- Dependency changes (adding/removing a pod like purchases_flutter) require a CLEAN
  build (`flutter clean` + `rm -rf ios/Pods ios/Podfile.lock` + pod reinstall). Pure
  Dart changes can skip the clean for a faster archive.
- `ascelerate builds upload build/ipa/App.ipa --yes` then
  `ascelerate apps build attach-latest <bundle> --yes` once it is `Valid`.

### H. Full production+distribution — what is CLI-automatable vs. a human/web-UI gate
Everything that CAN be automated, automate. The residual human gates are small and
specific. Complete map (from Adil's Auria run):

**Fully automatable (do these yourself):**
- Firebase project + billing link + Functions/Firestore/Hosting deploy.
- Anonymous auth enable (`identityPlatform:initializeAuth` then config PATCH).
- Bundle id + IAP capability, distribution profile, signed IPA, build upload, attach.
- Subscriptions: group + products + per-product localization + **group localization**.
- App Store listing: description/keywords/promo/subtitle/privacy URL in every locale,
  Support/Marketing URL (via `localizations update`).
- Age rating (API), copyright (API), review info + contact phone/notes.
- App icon (PIL, no-alpha), hosting pages (support/privacy/terms).

**Human / web-UI gates (cannot be done with the p8 API key):** do not keep a second copy of
the list here. It lives, complete and with the exact clicks, in
[HUMAN GATES](#-human-gates--the-complete-list-claude-cannot-do-these). The two that bite on
an iteration run: the **Sign in with Apple portal Save**, and **attaching the IAPs to the
version** before submitting.

**RevenueCat dashboard (human):** create project, connect App Store, entitlement +
offering + packages, get the public `appl_` key. Ask for the key/entitlement/offering
ids up front so the app is built against them.

> Net: with the p8 key + Firebase CLI + a distribution cert, a single agent can take
> an app from zero to a `Valid` TestFlight build and a 95%-complete App Store listing
> autonomously. The irreducible human steps are the ASC app record, subscription
> prices, App Privacy, the review demo video, and tapping "Submit".

### I. "Required to start the review" checklist — handle ALL of these up front
ASC shows a hard blocklist before it lets you submit. From Adil's Auria run, the full
set and how to clear each:

1. **Screenshots for every required display size.** A Flutter app defaults to
   **universal** (iPhone + iPad), so ASC demands **13-inch iPad** screenshots too.
   Decide device support in Phase 3:
   - Phone-only app → set **`TARGETED_DEVICE_FAMILY = "1"`** in
     `ios/Runner.xcodeproj/project.pbxproj` (all 3 build configs) BEFORE the first
     build. Then only iPhone 6.9" screenshots are required. (Auria did this.)
   - Universal → you must also upload iPad screenshots: 13" = **2064×2752**, slot
     `APP_IPAD_PRO_3GEN_129`, via `ascelerate apps media upload`.
2. **Content Rights Information** (App Information) → API, no web UI needed:
   `PATCH /v1/apps/{id}` `attributes.contentRightsDeclaration =
   "DOES_NOT_USE_THIRD_PARTY_CONTENT"` (or `USES_THIRD_PARTY_CONTENT`).
3. **Base price tier (Pricing)** — even a free app must pick the Free tier.
   Web UI is one click (Pricing and Availability → Price Schedule → Free). Via API:
   `POST /v1/appPriceSchedules` with the app, a base territory, and a manualPrice
   referencing the free `appPricePoint` (fiddly reservation format; the web click is
   faster). Do this before submit.
4. **App Privacy — Privacy Policy URL** (app-level, in the App Privacy section, not
   just the version localization). Set the version-localization `privacyPolicyURL`
   via `app-info` AND confirm the App Privacy page URL in the web UI (the app-level
   field is not reliably settable by the p8 key).
5. **App Privacy — data-collection practices (nutrition labels).** Web UI, and only
   an **Account Holder/Admin** can complete it. Declare honestly:
   - A private diary that stores entries in the user's own cloud space still
     "collects" (transmits off device) → declare the data types you send: e.g.
     **Health & Fitness** (the log), **Coarse Location** (if weather is on),
     **User Content** (notes) — each "Linked to the user" = No if you use an
     anonymous account, **Not used for tracking**, used only for **App Functionality**.
     Do NOT tick "Data Not Collected" if you use Firestore/an AI API — that is false
     and gets flagged (5.1.1). "We don't sell/track" is true and is what the policy
     text should stress; the nutrition label still lists the functional data.
6. **Age rating** (§D), **copyright** (§D), **review contact phone** (§E) — all API.

**Design rule for the next run:** clear items 1, 2, 6 automatically during setup
(device family + content rights + age rating + copyright via API), prepare 3/4/5 with
exact values, and hand the user a single short web-UI punch-list (Free price, App
Privacy URL + nutrition answers, subscription prices/trial + sub review screenshot,
first-submission demo video). Then `review submit`.

### J. More run-1 rules (legal, UX, dev hygiene, submission mechanics)
- **Terms of Use = the standard Apple EULA. Do NOT write your own Terms.** Point the
  in-app "Terms of Use" link (paywall + settings) and the store-description EULA line
  at `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`, opened
  externally. Keep your OWN Privacy Policy (Apple has no standard one). Leave the ASC
  app-level License Agreement on its default (= standard Apple EULA); don't upload a
  custom one. A self-written "terms" doc reads as a red flag and is unnecessary.
- **Account deletion must return to a clean first launch.** After `deleteAccount`,
  reset premium, set `onboarded = false`, sign in a fresh anonymous user, and navigate
  to onboarding — not back into the (now-empty) app.
- **Never ship dev-only affordances.** A "skip paywall" test button must be gated with
  `if (kDebugMode)` so it is compiled out of release/TestFlight, and removed before the
  final build anyway. Reviewers reject visible test/debug controls (Guideline 4.0).
- **Health apps: avoid the word "doctor" in marketing copy** — see [Gotcha 11](#11-health--medical-apps).
- **Disk fills up when iterating** (~10-15 GB per archive) — see the pitfalls table.
  Pure-Dart changes → fast rebuild (reuse Pods); dependency changes → clean rebuild.
- **Submission mechanics.** The single review submission is built up then finalized.
  `ascelerate apps review submit` DOES detect and offer to include the subscription
  group + subscriptions (good). It stages the submission (state `READY_FOR_REVIEW`,
  `submitted=null`); the human clicks **Submit for Review** in the web UI (which
  reliably includes their IAPs) OR you finalize by PATCHing `submitted=true`. A staged,
  non-submitted draft cannot be `canceled=true` (409) or DELETEd (403) via the p8 key —
  only the account can discard it in the web UI. So: attach the build, stage nothing
  risky, and let the account holder press Submit. If subscriptions 409 with
  "not in a valid state," the usual causes are an inactive **Paid Applications
  Agreement** or incomplete **App Privacy** — but on an established account with the
  agreement active and IAPs already added, just hand off the final Submit to the user.

---

## 🧱 RECOMMENDED STACK (default — adapt to the idea)

Flutter (3.35+) · Firebase (Auth / Firestore / Functions v2 / Storage / FCM) · Node 22 · an AI provider (image/video/text) · RevenueCat (subscriptions+IAP) · sharp/WebP (media optimization) · optional a CDN (media) · ascelerate (App Store Connect CLI) · gen-l10n (multi-language) · optional: Firebase Crashlytics + Analytics (crash/usage tracking).

---

> **Claude:** run PHASE 0 silently, then open with the Phase 1 question. Set the scope from the
> user's answer, work the phases in order, stop at every 🙋 gate and explain *why* it is a gate,
> stay green at every step. The user is learning as much as they are shipping. 🚀
