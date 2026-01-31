# CleanConnect - Final Steps for App Store Submission

*Last Updated: January 30, 2026*

---

## Pre-Submission Checklist

| Item | Status |
|------|--------|
| Developer Account | ✅ Complete |
| Firebase Backend | ✅ Deployed |
| Firestore Rules | ✅ Deployed |
| Firestore Indexes | ✅ Deployed |
| Cloud Functions (11) | ✅ Deployed |
| App Icon (1024x1024) | ✅ Created |
| Screenshots | ✅ Taken |
| Legal Pages on Website | ✅ Hosted |
| Stripe Connect | ⏳ Awaiting Approval |
| App Store Connect | ⬜ Ready to Setup |

---

## Step 1: App Store Connect Setup

### 1.1 Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** (blue plus button) → **New App**
3. Fill in the following:

| Field | Value |
|-------|-------|
| Platform | iOS |
| Name | CleanConnect |
| Primary Language | English (U.S.) |
| Bundle ID | com.cleanconnect.app |
| SKU | cleanconnect-ios-2026 |
| User Access | Full Access |

4. Click **Create**

---

### 1.2 App Information Tab

Navigate to **App Store** → **App Information**

#### General Information

| Field | Value |
|-------|-------|
| Name | CleanConnect |
| Subtitle | Clean India Together |
| Category | Lifestyle (Primary) |
| Secondary Category | Social Networking |
| Content Rights | Does not contain third-party content |

#### Age Rating

Click **Edit** next to Age Rating and answer:

| Question | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use | None |
| Mature/Suggestive Themes | None |
| Simulated Gambling | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |

**Result: Age Rating 4+**

---

### 1.3 Pricing and Availability

Navigate to **Pricing and Availability**

| Setting | Value |
|---------|-------|
| Price | Free |
| Availability | All territories (or select India only initially) |
| Pre-Orders | No |

---

### 1.4 App Privacy

Navigate to **App Privacy**

#### Privacy Policy URL
```
https://thebighead.ca/cleanconnect/privacy
```

#### Data Collection

Click **Get Started** and declare the following data types:

**1. Contact Info**
- Name ✓ (for profile display)
- Email Address ✓ (for account creation)
- Purpose: App Functionality
- Linked to User: Yes

**2. User Content**
- Photos or Videos ✓ (cleanup proof)
- Purpose: App Functionality
- Linked to User: Yes

**3. Identifiers**
- User ID ✓ (Firebase Auth)
- Purpose: App Functionality
- Linked to User: Yes

**4. Location**
- Coarse Location ✓ (state/district selection)
- Purpose: App Functionality
- Linked to User: Yes

**5. Financial Info** (if Stripe is enabled)
- Payment Info ✓ (tips/donations)
- Purpose: App Functionality
- Linked to User: Yes

---

### 1.5 App Store Listing (Version Information)

Navigate to your app version (e.g., **1.0**)

#### Screenshots

Upload screenshots for:

**iPhone 6.7" Display (Required)**
- Resolution: 1290 × 2796 pixels
- Devices: iPhone 15 Pro Max, iPhone 15 Plus, iPhone 14 Pro Max

**iPhone 6.5" Display (Optional but recommended)**
- Resolution: 1242 × 2688 pixels
- Devices: iPhone 11 Pro Max, iPhone XS Max

**Recommended Screenshot Order:**
1. Feed View - Show posts with upvotes and video badges
2. Create Post - Show video link input field
3. Post Detail - Show map, comments, tip button
4. Leaderboard - Show top cleaners with points
5. Events - Show community cleanup events
6. Profile - Show user stats and badges

#### App Preview (Optional)
- 15-30 second video showing app functionality
- Same resolution as screenshots

---

#### Promotional Text (170 characters max)
```
Make a difference in your neighborhood. Document your cleanup efforts with video proof and inspire others across India.
```

#### Description
```
CleanConnect - India's Community Cleanup Platform

Make a difference in your neighborhood. Document your cleanup efforts with video proof and inspire others across India.

KEY FEATURES:

VIDEO PROOF SYSTEM
Link your YouTube Shorts or Instagram Reels to verify your cleanup. Verified posts earn more trust and tips.

COMMUNITY VOTING
Upvote genuine cleanups, downvote suspicious ones. Sort by Top, New, or Most Tipped.

EARN TIPS
Receive tips from grateful community members. Only 7% platform fee - you keep 93%.

LOCAL IMPACT
Filter posts by your State or District. See cleanups happening near you.

LEADERBOARD
Compete with other cleaners. Earn points for every cleanup and climb the rankings.

COMMUNITY EVENTS
Join or organize cleanup events in your area. Coordinate with other volunteers.

ALL INDIA COVERAGE
Every state and district supported. From Kashmir to Kanyakumari.

SAFETY FIRST
We remind users to prioritize safety when attending events. Don't go alone!

#SwachhBharat #CleanIndia
```

#### Keywords (100 characters max)
```
cleanup,swachh bharat,clean india,environment,garbage,waste,tips,earn,volunteer,green
```

#### Support URL
```
https://thebighead.ca/cleanconnect/support
```

#### Marketing URL (Optional)
```
https://thebighead.ca/cleanconnect
```

#### Version
```
1.0.0
```

#### What's New in This Version
```
Initial release of CleanConnect - India's cleanup community platform!

• Post cleanup videos with YouTube/Instagram links
• Upvote and downvote posts
• Send and receive tips
• Join community cleanup events
• Climb the leaderboard
• Filter by state and district
```

#### Copyright
```
© 2025 The Big Head
```

---

### 1.6 App Review Information

#### Contact Information

| Field | Value |
|-------|-------|
| First Name | [Your First Name] |
| Last Name | [Your Last Name] |
| Phone Number | [Your Phone] |
| Email | info@thebighead.ca |

#### Sign-In Required
- **No** (users can browse without signing in, or use Sign in with Apple)

#### Notes for Reviewer
```
CleanConnect is a community platform for environmental cleanup activities in India.

TO TEST:
1. Sign in with Apple or Google
2. Browse the feed to see cleanup posts
3. Create a test post with a YouTube link (e.g., https://youtube.com/shorts/dQw4w9WgXcQ)
4. Upvote/downvote posts
5. Check the leaderboard
6. Browse community events

PAYMENT FEATURES:
Tipping requires Stripe Connect setup. The tip feature allows users to send monetary tips to cleanup volunteers. Platform takes 7% fee, creator receives 93%.

Note: Stripe Connect is pending approval. Payment features may show errors until approved.

No demo account needed - the app supports Sign in with Apple.
```

#### Attachment (Optional)
- You can attach a demo video if needed

---

## Step 2: Build and Archive

### 2.1 Pre-Archive Checklist

1. **Update Version & Build Number in Xcode**
   - Select project in navigator
   - Select target "CleanConnect"
   - General tab → Version: `1.0.0`, Build: `1`

2. **Verify Bundle ID**
   - Should be: `com.cleanconnect.app`

3. **Verify Signing**
   - Team: Your Apple Developer Team
   - Signing Certificate: Distribution
   - Provisioning Profile: Automatic or App Store

4. **Select Generic iOS Device**
   - In Xcode toolbar, select "Any iOS Device (arm64)"

### 2.2 Create Archive

1. **Clean Build Folder**
   ```
   Product → Clean Build Folder (⌘⇧K)
   ```

2. **Archive**
   ```
   Product → Archive (⌘⇧B first to build, then Archive)
   ```

3. Wait for archive to complete (this may take a few minutes)

4. **Organizer Window** will open automatically showing your archive

### 2.3 Upload to App Store Connect

1. In **Organizer**, select your archive
2. Click **Distribute App**
3. Select **App Store Connect** → **Next**
4. Select **Upload** → **Next**
5. Options:
   - ✅ Include bitcode for iOS content
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number
6. Click **Next**
7. Select your **Distribution Certificate** and **Provisioning Profile**
8. Click **Upload**
9. Wait for upload to complete

### 2.4 Processing Time

After upload:
- App Store Connect will process your build
- This takes 5-30 minutes
- You'll receive an email when ready
- Build will appear under your app version in App Store Connect

---

## Step 3: Submit for Review

### 3.1 Select Build

1. Go to App Store Connect → Your App → Version 1.0
2. Scroll to **Build** section
3. Click **+** to select a build
4. Choose your uploaded build
5. Click **Done**

### 3.2 Final Review

Before submitting, verify:

- [ ] All screenshots uploaded
- [ ] Description filled in
- [ ] Keywords added
- [ ] Privacy policy URL working
- [ ] Support URL working
- [ ] Age rating completed
- [ ] App privacy declarations done
- [ ] Build selected
- [ ] Review notes added

### 3.3 Submit

1. Click **Add for Review** (top right)
2. Answer export compliance questions:
   - "Does your app use encryption?" → **No**
   - (If yes, answer follow-up questions)
3. Click **Submit to App Review**

---

## Step 4: App Review Process

### 4.1 Timeline

| Review Type | Typical Duration |
|-------------|-----------------|
| Standard Review | 24-48 hours |
| Expedited Review | 24 hours (request separately) |

### 4.2 Possible Outcomes

**Approved** ✅
- App goes live immediately (or on your scheduled date)
- You'll receive a confirmation email

**Rejected** ❌
- You'll receive detailed feedback
- Common reasons:
  - Crashes or bugs
  - Incomplete features
  - Privacy policy issues
  - Missing functionality
  - Misleading descriptions
- Fix issues and resubmit

**In Review** 🔄
- App is being tested by Apple reviewer
- May take 24-48 hours

**Metadata Rejected** ⚠️
- Only app listing info needs changes
- App binary is fine
- Fix metadata and resubmit

### 4.3 Responding to Rejection

If rejected:
1. Read the rejection reason carefully
2. Go to **Resolution Center** in App Store Connect
3. Fix the issues
4. Either:
   - Reply explaining your changes
   - Submit a new build
5. Resubmit for review

---

## Step 5: Post-Launch

### 5.1 Monitor Launch

**Day 1-3:**
- Check crash reports in Xcode Organizer
- Monitor Firebase logs: `npx firebase functions:log`
- Respond to any App Store reviews
- Watch for user feedback

### 5.2 Crash Monitoring

In Xcode:
```
Window → Organizer → Crashes
```

In Firebase:
```bash
cd /Users/user291996/Desktop/CleanConnect/functions
npx firebase functions:log --only crashlytics
```

### 5.3 App Store Reviews

- Respond to reviews in App Store Connect
- Address negative feedback promptly
- Thank positive reviewers

---

## Troubleshooting

### Build Fails

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build
Product → Clean Build Folder (⌘⇧K)

# Rebuild
Product → Build (⌘B)
```

### Archive Fails

1. Verify signing certificates in Keychain Access
2. Check provisioning profiles in Xcode → Preferences → Accounts
3. Ensure Bundle ID matches App Store Connect

### Upload Fails

1. Check internet connection
2. Verify App Store Connect credentials
3. Try Application Loader (alternative upload method):
   ```
   Xcode → Open Developer Tool → Application Loader
   ```

### "Missing Compliance" Error

After upload, if you see this:
1. Go to App Store Connect → Your App → TestFlight
2. Click on the build
3. Click "Manage" next to "Missing Compliance"
4. Answer: "No" to encryption question (unless you use custom encryption)

---

## Important URLs

| Service | URL |
|---------|-----|
| App Store Connect | https://appstoreconnect.apple.com |
| Apple Developer | https://developer.apple.com |
| Firebase Console | https://console.firebase.google.com/project/cleanconnect-b7c67 |
| Stripe Dashboard | https://dashboard.stripe.com |
| Privacy Policy | https://thebighead.ca/cleanconnect/privacy |
| Terms of Service | https://thebighead.ca/cleanconnect/terms |
| Support Page | https://thebighead.ca/cleanconnect/support |

---

## Contact Information

| Type | Value |
|------|-------|
| Support Email | info@thebighead.ca |
| Developer | The Big Head |
| Website | https://thebighead.ca |

---

## Stripe Connect (When Approved)

Once Stripe Connect is approved:

### Test Payment Flow

1. Open the app
2. Find a post with the "Tip" button
3. Tap "Tip"
4. Use test card: `4242 4242 4242 4242`
5. Any future expiry, any CVC
6. Complete payment
7. Verify in Stripe Dashboard

### Webhook Verification

Ensure webhook is receiving events:
```
https://us-central1-cleanconnect-b7c67.cloudfunctions.net/stripeWebhook
```

Events to monitor:
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `account.updated`

---

## Version History

| Version | Build | Date | Notes |
|---------|-------|------|-------|
| 1.0.0 | 1 | Jan 2026 | Initial release |

---

*Good luck with your submission!*

*CleanConnect - Clean India Together*
