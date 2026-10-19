# CleanConnect 1.1.0 — Submission Steps

## What's already done

- Version bumped to **1.1.0** (build **1**) in `Info.plist`, `project.pbxproj` (both Debug & Release), and `Utils/Constants.swift`.
- `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` removed from `Info.plist` — we no longer access either, and App Review rejects apps that declare unused permissions.
- `NSLocationWhenInUseUsageDescription` kept and rewritten to match actual usage (event proximity + post tagging).
- `UIRequiredDeviceCapabilities` corrected from the legacy `armv7` to `arm64`.
- `RELEASE_NOTES_1.1.0.md` contains the paste-ready "What's New in This Version" text for App Store Connect.
- `build/ExportOptions.plist` is ready (team `F385ZL83XQ`, automatic signing, `app-store-connect` method, `destination: export`).
- A Release `.xcarchive` is being built at `./build/CleanConnect-1.1.0.xcarchive`.

## Once the archive completes — your two upload paths

### Path A: Xcode Organizer (most foolproof)

1. Open Xcode → **Window** → **Organizer**. Select the **Archives** tab.
2. You should see the new `CleanConnect 1.1.0 (1)` archive. If you don't, drag `./build/CleanConnect-1.1.0.xcarchive` into the Organizer or open it from Finder.
3. Click **Distribute App**.
4. Choose **App Store Connect** → **Upload**.
5. Xcode handles signing, symbol upload (for crash reports), and the App Store Connect handshake.
6. After upload completes, processing on Apple's side takes 10–30 min.
7. Log in to App Store Connect → **CleanConnect** → **App Store** → **+** to add a new version (1.1.0) → pick the just-uploaded build → paste the release notes from `RELEASE_NOTES_1.1.0.md` → submit for review.

### Path B: Command line + Transporter

1. After the archive succeeds, run:
   ```sh
   cd ~/Downloads/CleanConnect
   xcodebuild -exportArchive \
     -archivePath ./build/CleanConnect-1.1.0.xcarchive \
     -exportOptionsPlist ./build/ExportOptions.plist \
     -exportPath ./build/Export \
     -allowProvisioningUpdates
   ```
2. This produces `./build/Export/CleanConnect.ipa`.
3. Open the **Transporter** app from the Mac App Store (free).
4. Sign in with the same Apple ID that owns the developer account.
5. Drag `CleanConnect.ipa` into Transporter → **Deliver**.
6. Same App Store Connect steps as Path A from step 7.

## If the archive fails

- **"No signing certificate found"** — open Xcode → **Settings** → **Accounts** → make sure your Apple ID is added and `F385ZL83XQ` shows up. Click **Manage Certificates** and add an Apple Distribution certificate if missing.
- **"No profiles for 'ca.thebighead.cleanconnect' were found"** — in Xcode, open the project → CleanConnect target → **Signing & Capabilities** → toggle "Automatically manage signing" off and on again, or click "Try Again" when it appears.
- **"This bundle is invalid. The Info.plist contains an invalid key"** — let me know which key Apple flagged; usually it's a `UIRequiredDeviceCapabilities` or a Stripe leftover.

## Reviewer hints

Apple's automated review WILL look for:
- The four URL schemes in `Info.plist` (`com.googleusercontent.apps.*`) — declares Google Sign-in. Keep.
- Reasonable privacy descriptions — done.
- No declared-but-unused permissions — done (camera/photo library removed).
- A working main flow — make sure the Apple ID test reviewer account can sign in and see Events / Feed without errors.

## Known dead code (post-shipping cleanup, doesn't affect review)

Services that backed retired flows still compile but are never called: `StripeService`, `PaymentService`, `BookingService`, `CleanupRequestService`, and the `CleaningCompany` / `CleanupJob` models. They can be safely deleted in a 1.1.1 cleanup release.
