# CleanConnect 2.0

Community app for cleaning up India: report dirty spots on a live map, clean them up with before/after photos, organise cleanup drives, and earn Swachh Points. English + Hindi. iOS 18+, iPhone and iPad.

App Store: https://apps.apple.com/app/id6758537635 · Bundle `ca.thebighead.cleanconnect` · Team `F385ZL83XQ`

## Project layout

```
project.yml                 XcodeGen spec (run `xcodegen generate` after adding files)
CleanConnect/
  App/                      App entry, RootView, tabs, Router (navigation + demo launch hooks)
  Core/Models/              Spot, Drive, Profile (+ levels, badges, points), Comment, Doc (lenient Firestore reader)
  Core/Services/            Session (auth), SpotAPI, DriveAPI, ProfileAPI, LocationService, UPI, Reminders, ImagePipeline
  Core/Demo/                Sample data for `-demo` launches (screenshots). DemoAssets are excluded from Release.
  DesignSystem/             Theme, buttons, components, before/after slider, photo input
  Features/                 Home, Map, Spot (report, detail, cleanup, complaint, share cards), Drives, Leaderboard, Profile, Settings
  Resources/                Info.plist, entitlements, privacy manifest, assets, Localizable/InfoPlist string catalogs (en + hi)
functions-v2/               Cloud Functions (codebase "v2"): points, streaks, counters, stats, moderation, deleteAccount
functions/                  Legacy 1.x functions (Stripe etc.), still used by the old app — don't deploy changes here
firestore.rules             v2 rules first, legacy 1.x rules preserved below
backend-tests/              Emulator tests for rules + triggers
AppStore/                   Listing copy, review notes, screenshots, capture/compose tools
WebPages/                   Website pages (publish via the "THEBIGHEAD Website" session, not direct upload)
```

## Data model (Firestore)

| Collection | Written by | Notes |
|---|---|---|
| `profiles/{uid}` | owner (name, bio, city, UPI…) + functions (points, counters, streaks) | public |
| `userPrivate/{uid}` | owner | block list, terms acceptance |
| `spots/{id}` | reporter / claimer / cleaner (rules enforce transitions open → claimed → cleaned) | `gh3`/`gh4` geohash prefixes for map queries |
| `spots/{id}/reactions/{uid}_{type}` | owner | respect · stillThere · verified |
| `spots/{id}/comments`, `drives/{id}/comments` | author | |
| `drives/{id}`, `drives/{id}/attendees/{uid}` | organiser / attendee | |
| `flags/{id}` | any signed-in user (write-only) | 3 distinct reporters auto-hide content |
| `stats/india`, `cityStats/{state\|city}` | functions only | |

Points (keep `Core/Models/Profile.swift` and `functions-v2/index.js` in sync): report 10 · cleanup 50 + 5/bag (max 20) · your report cleaned 10 · verify 5 · join drive 15 · host drive 20 · complete drive 30 + 5/bag. Weeks and streak days use IST.

## Common tasks

```bash
xcodegen generate
xcodebuild -project CleanConnect.xcodeproj -scheme CleanConnect -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
```

Backend tests (needs Java: `brew install openjdk@21`):

```bash
cd backend-tests && npm install && cd .. && PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH" npx firebase-tools emulators:exec --config firebase.test.json --only auth,firestore,functions --project demo-cleanconnect 'NODE_PATH=backend-tests/node_modules node --test --test-concurrency=1 backend-tests/rules.test.js backend-tests/functions.test.js backend-tests/delete.test.js'
```

Deploy backend (project `cleanconnect-b7c67`):

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage --project cleanconnect-b7c67
firebase deploy --only functions:v2 --project cleanconnect-b7c67
```

Screenshots: build for the simulator, then `AppStore/tools/capture.sh <udid> <en|hi> <out> <app>` and compose with `AppStore/tools/compose_screenshots.swift` (see the spec format in that file). Demo launch flags: `-demo -tab map|drives|leaders|profile -push spot:s1|drive:d1|complaint:s2 -sheet report|drive|support`.

## Moderation

Reports land in the `flags` collection (Firebase console). Review within 24 hours. Remove offending docs or set `hidden: true`, and disable abusive accounts in Firebase Auth.
