# CleanConnect - Final Steps to Publish

## Pre-Submission Checklist

### 1. Apple Developer Account Setup

- [ ] **Apple Developer Program** - Ensure your $99/year membership is active
- [ ] **App Store Connect** - App already created (you mentioned this)
- [ ] **Certificates & Profiles** - Generate distribution certificate and provisioning profile

### 2. Firebase Setup (Required for Google/Apple Sign-In)

#### A. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: "CleanConnect"
3. Enable Google Analytics (optional but recommended)

#### B. Add iOS App to Firebase
1. Click "Add App" → iOS
2. Enter Bundle ID: `com.cleanconnect.app`
3. Download `GoogleService-Info.plist`
4. Add to Xcode project (drag to CleanConnect folder, check "Copy items if needed")

#### C. Enable Authentication Providers
1. Go to Authentication → Sign-in method
2. Enable **Apple** provider:
   - Add your Service ID from Apple Developer
3. Enable **Google** provider:
   - Configure OAuth consent screen
   - Note your Web Client ID

### 3. Add SDK Dependencies in Xcode

#### Firebase SDK
```
File → Add Package Dependencies
URL: https://github.com/firebase/firebase-ios-sdk
Select products: FirebaseAuth, FirebaseCore
```

#### Google Sign-In SDK
```
File → Add Package Dependencies
URL: https://github.com/google/GoogleSignIn-iOS
Select products: GoogleSignIn
```

### 4. Xcode Configuration

#### A. Capabilities (Target → Signing & Capabilities)
- [ ] Add **Sign in with Apple**
- [ ] Ensure **Push Notifications** is enabled (for future use)

#### B. Info.plist Additions
Add URL Scheme for Google Sign-In:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

#### C. Uncomment Firebase Code
After adding SDKs, uncomment these sections:

**CleanConnectApp.swift** (lines 10, 19):
```swift
import FirebaseCore
// ...
FirebaseApp.configure()
```

**AuthenticationService.swift** - Uncomment all Firebase integration sections marked with:
```swift
// === FIREBASE INTEGRATION ===
```

### 5. App Store Connect Configuration

#### A. App Information
- [ ] App name: CleanConnect
- [ ] Subtitle: Community Cleanup Events
- [ ] Category: Social Networking (Primary), Lifestyle (Secondary)
- [ ] Content Rights: Confirm you have rights to all content

#### B. Pricing & Availability
- [ ] Price: Free
- [ ] Availability: India (or worldwide)

#### C. App Privacy
Create privacy policy and add details for:
- [ ] **Contact Info** - Email, Name (for Sign-In)
- [ ] **Location** - Approximate location for events
- [ ] **User Content** - Photos, posts, comments
- [ ] **Identifiers** - User ID, Device ID

**Required URLs:**
- Privacy Policy: Create at `https://cleanconnect.app/privacy`
- Terms of Service: Create at `https://cleanconnect.app/terms`
- Support URL: Create at `https://cleanconnect.app/support`

#### D. Screenshots Required
Prepare screenshots for:
- iPhone 6.7" (iPhone 15 Pro Max) - 6 screenshots
- iPhone 6.5" (iPhone 11 Pro Max) - 6 screenshots
- iPad 12.9" (optional but recommended)

**Recommended Screenshot Scenes:**
1. Events home screen with upcoming events
2. Event detail with discussion forum
3. Task assignment feature
4. Supply contribution view
5. Feed with cleanup posts
6. Profile with badges/achievements

#### E. App Preview Video (Optional but Recommended)
- 15-30 second video showing key features
- Resolution: 1080p minimum

### 6. TestFlight Beta Testing

Before public release:

1. **Archive & Upload**
   ```
   Product → Archive → Distribute App → App Store Connect
   ```

2. **Internal Testing**
   - Add team members as Internal Testers
   - Test all sign-in flows
   - Test event creation and participation
   - Test supply contributions

3. **External Testing (Recommended)**
   - Add 25-100 beta testers
   - Collect feedback via TestFlight
   - Fix critical bugs

### 7. Final Review Checklist

#### Technical Requirements
- [ ] Builds without errors (BUILD SUCCEEDED)
- [ ] No crashes on launch
- [ ] Sign in with Apple works (required by App Store)
- [ ] Sign in with Google works
- [ ] Guest mode works
- [ ] Account deletion works (required since 2022)
- [ ] All links (privacy, terms) are live

#### Content Guidelines
- [ ] No placeholder content (Lorem Ipsum, test data)
- [ ] All images are appropriate
- [ ] Safety warnings are visible
- [ ] No broken UI elements

#### Performance
- [ ] App launches in < 5 seconds
- [ ] Smooth scrolling (60fps)
- [ ] No memory leaks
- [ ] Works offline gracefully

### 8. Submission

1. **Create New Version** in App Store Connect
2. **Add Build** from TestFlight
3. **Complete all metadata**
4. **Submit for Review**

#### Review Timeline
- First submission: 24-48 hours typically
- Rejections: Address feedback, resubmit

### 9. Common Rejection Reasons & Fixes

| Rejection Reason | Fix |
|-----------------|-----|
| Sign in with Apple missing | Already implemented |
| No account deletion | Already implemented in AccountSettingsView |
| Privacy policy missing | Add live URL to App Store Connect |
| Placeholder content | Remove all test/mock data |
| Crashes on launch | Test on real devices |
| Metadata inconsistency | Match app content with screenshots |

### 10. Post-Launch

#### A. Monitor
- Crash reports in Xcode Organizer
- User reviews in App Store Connect
- Firebase Analytics (if enabled)

#### B. First Update (1-2 weeks after launch)
- Fix any reported bugs
- Respond to user feedback
- Add minor improvements

---

## Quick Reference Commands

### Build for Release
```bash
xcodebuild -scheme CleanConnect -configuration Release -destination 'generic/platform=iOS' archive
```

### Test on Device
```bash
xcodebuild -scheme CleanConnect -destination 'platform=iOS,name=Your iPhone'
```

### Clean Build
```bash
xcodebuild clean -scheme CleanConnect
```

---

## Support & Resources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Sign in with Apple Guidelines](https://developer.apple.com/sign-in-with-apple/get-started/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

## Contact

For any issues during submission, the most common solution is to:
1. Read the rejection reason carefully
2. Check Apple's guidelines for that specific issue
3. Make the minimum required change
4. Resubmit with detailed notes to the reviewer

Good luck with your launch! 🎉
