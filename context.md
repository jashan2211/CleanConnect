# CleanConnect - Project Context

*Last Updated: February 14, 2026*

---

## App Overview

| Field | Value |
|-------|-------|
| **App Name** | CleanConnect |
| **Subtitle** | Clean India Together |
| **Bundle ID** | `ca.thebighead.cleanconnect` |
| **Version** | 1.0.0 |
| **Build** | 2 |
| **Category** | Lifestyle (Primary), Social Networking (Secondary) |
| **Minimum iOS** | iOS 17.0 |
| **Developer** | The Big Head |
| **Firebase Project** | cleanconnect-b7c67 |
| **Development Team** | F385ZL83XQ |

---

## Current Status

| Item | Status |
|------|--------|
| Build Succeeds | ✅ |
| Sign in with Apple | ✅ Fixed (entitlements + Firebase OAuth code flow) |
| Sign in with Google | ✅ Working |
| Firebase Auth | ✅ Apple + Google providers enabled |
| Firebase Firestore | ✅ Deployed |
| Cloud Functions (11) | ✅ Deployed |
| Stripe Connect | ⏳ Awaiting Approval |
| Tips UI (graceful fallback) | ✅ Shows "Tips Coming Soon" when Stripe unavailable |
| Privacy Manifest | ✅ Committed |
| App Store Submission | ❌ Rejected → Fixes applied → Ready to resubmit |

---

## App Store Rejection (February 2026) — RESOLVED

### Issue 1: Guideline 2.1 — Sign in with Apple Error
**Root Cause:** Missing `.entitlements` file and Firebase Apple OAuth code flow not configured.

**Fixes Applied:**
1. Created `CleanConnect/CleanConnect.entitlements` with `com.apple.developer.applesignin`
2. Added `CODE_SIGN_ENTITLEMENTS` to project.pbxproj (Debug + Release)
3. Configured Apple Services ID in Apple Developer Portal
4. Enabled OAuth code flow in Firebase Console (Team ID, Key ID, .p8 private key)
5. Added `AuthenticationError.cancelled` handling in `AuthView.swift` so cancelling doesn't show error

### Issue 2: Guideline 2.3.3 — iPad Screenshots Show Only Login
**Status:** Manual fix needed — take new 13-inch iPad screenshots showing app content (Feed, Events, Leaderboard, Profile tabs)

---

## Full App Review Fixes (Build 2)

### 1. Non-functional Buttons Fixed
- **PostCard.swift**: Comments → `NavigationLink` to `PostDetailView`; Share → `ShareLink`
- **ProfileView.swift**: Removed 5 non-functional menu items (Saved Posts, My Squad, My Events, Refer & Earn, Help & Support)

### 2. Placeholder Settings Removed
- **SettingsView.swift**: Removed 7 placeholder NavigationLinks; kept Edit Profile + real Links for Terms/Privacy URLs
- **EditProfileView.swift**: Removed non-functional Change Photo button

### 3. Hardcoded Sample Data Replaced
- **LeaderboardTabView.swift**: Error fallback uses empty arrays (not sample data); fixed podium for <3 users
- **GatheringService.swift**: `getSupplyRequests()` returns empty array
- **EventDetailView.swift**: Replaced hardcoded chat messages with empty state
- **EventSuppliesView.swift**: `totalContributors` calculated from actual data (not hardcoded 10)

### 4. RSVP & Donation Flows Connected
- **EventDetailView.swift**: `submitRSVP()` calls `GatheringService.shared.rsvp()`; `submitDonation()` calls `GatheringService.shared.contribute()`

### 5. Account Deletion Fixed (App Store Requirement)
- **AuthenticationService.swift**: Added `FirebaseFirestore` import; `deleteAccount()` now deletes user doc, posts, and tips from Firestore before deleting Firebase Auth account

### 6. Empty States for New Users
- **UserState.swift**: Removed fake "Ready to make an impact!" hardcoded activity
- **ProfileView.swift**: Badges section hidden when user has 0 badges; Recent Activity section hidden when empty

### 7. Stripe Tips Graceful Fallback
- **TipSheet.swift**: Checks creator's `stripeAccountId` + `stripeOnboardingComplete` before showing tip UI; shows "Tips Coming Soon" banner if creator can't receive tips

---

## Architecture

### Authentication Flow
1. User taps Sign in with Apple/Google on `AuthView.swift`
2. `AuthenticationService.swift` handles nonce generation, Firebase credential exchange
3. `createOrUpdateUser()` saves to local storage + Firestore
4. `AuthManager.swift` manages auth state; `UserState.swift` loads user data
5. `ContentView.swift` switches between `AuthView` and main tab view based on auth state

### Key Services
| Service | File | Purpose |
|---------|------|---------|
| AuthenticationService | `Services/AuthenticationService.swift` | Apple/Google sign-in via Firebase Auth |
| AuthManager | `Services/AuthManager.swift` | Auth state management |
| UserState | `Services/UserState.swift` | Current user session, badges, wallet |
| FirestoreService | `Services/FirestoreService.swift` | Firestore CRUD operations |
| GatheringService | `Services/GatheringService.swift` | Event creation, RSVP, donations |
| PaymentService | `Services/PaymentService.swift` | Stripe payment orchestration |
| StripeService | `Services/StripeService.swift` | Stripe Cloud Functions integration |
| CloudFunctionsService | `Services/CloudFunctionsService.swift` | Firebase Cloud Functions calls |

### Main Tabs (ContentView)
1. **Feed** — Cleanup posts with voting, tips, filters
2. **Events** — Community cleanup gatherings
3. **Leaderboard** — Top Givers & Top Earners rankings
4. **Profile** — User stats, badges, settings

---

## Payment System

| Item | Value |
|------|-------|
| Provider | Stripe Connect |
| Platform Fee | 7% |
| Creator Share | 93% |
| Tip Range | ₹10 — ₹10,000 |
| Status | ⏳ Stripe Connect account under approval |
| Graceful Fallback | "Tips Coming Soon" banner shown when creator can't receive tips |

### Cloud Functions for Payments
| Function | Purpose |
|----------|---------|
| `createConnectAccount` | Create Stripe Connect account for creators |
| `checkConnectStatus` | Check if creator's Stripe is active |
| `createTipPaymentIntent` | Create payment intent for tips |
| `stripeWebhook` | Handle Stripe webhook events |
| `createDashboardLink` | Create Stripe dashboard link |

---

## Build & Deploy

```bash
# Build for simulator
xcodebuild -scheme CleanConnect -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Deploy Firebase functions
cd functions && npx firebase deploy --only functions

# Deploy Firestore rules
npx firebase deploy --only firestore:rules

# Check function logs
npx firebase functions:log
```

### Available Simulators (Xcode 17C52, iOS 26.2)
- iPhone 17, iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air, iPhone 16e
- iPad (A16), iPad Air 11/13", iPad Pro 11/13", iPad mini

---

## Remaining TODO for Resubmission

- [ ] Take new 13-inch iPad screenshots showing app content (not login screen)
- [ ] Archive and upload Build 2 to App Store Connect
- [ ] Update reviewer notes mentioning Sign in with Apple fix
- [ ] Submit for review

---

## Version History

| Version | Build | Date | Notes |
|---------|-------|------|-------|
| 1.0.0 | 1 | Jan 2026 | Initial submission — rejected |
| 1.0.0 | 2 | Feb 14, 2026 | Fix Sign in with Apple, remove fake data, polish UI, account deletion |

---

## Important URLs

| Service | URL |
|---------|-----|
| Firebase Console | https://console.firebase.google.com/project/cleanconnect-b7c67 |
| Stripe Dashboard | https://dashboard.stripe.com |
| App Store Connect | https://appstoreconnect.apple.com |
| Privacy Policy | https://thebighead.ca/cleanconnect/privacy |
| Terms of Service | https://thebighead.ca/cleanconnect/terms |
| Support Page | https://thebighead.ca/cleanconnect/support |

---

*CleanConnect - Clean India Together*
