# CleanConnect - Remaining Steps to Launch

## ✅ Completed

- Firebase Authentication (Google + Apple)
- Firebase Firestore Database
- Firebase Storage
- Firebase Functions (payment backend)
- Security rules deployed
- Stripe secret key configured
- Stripe webhook configured
- Stripe Connect enabled
- Xcode packages added (Firebase + Stripe)
- Guest mode removed (SignInView.swift, AuthManager.swift)
- Account deletion feature
- All iOS code updates
- Firebase enabled in AppConfiguration (isFirebaseEnabled = true)
- Platform fee set to 7% (Constants.swift + functions/index.js)
- All URLs updated to thebighead.ca/CleanConnect/

---

## Step 1: Create Web Pages (15 minutes)

Create these 3 pages on your website (thebighead.ca):

### Privacy Policy (`thebighead.ca/CleanConnect/privacy`)
Must include:
- What data you collect (name, email, location, photos, payment info)
- How you use the data
- Third parties (Firebase, Stripe)
- User rights (delete account, access data)
- Contact information

### Terms of Service (`thebighead.ca/CleanConnect/terms`)
Must include:
- User responsibilities
- Content guidelines
- Payment terms (10% platform fee)
- Limitation of liability
- Termination policy

### Support (`thebighead.ca/CleanConnect/support`)
Must include:
- Contact email
- FAQ section
- How to report issues

---

## Step 2: Test on Physical iPhone (15 minutes)

Apple Sign-In only works on real devices.

1. Connect your iPhone to Mac with cable
2. In Xcode, select your iPhone from device dropdown (top bar)
3. Build and run (Cmd + R)
4. Test these features:
   - [ ] Apple Sign-In works
   - [ ] Google Sign-In works
   - [ ] Create a post with photos
   - [ ] Photos upload successfully
   - [ ] Send a tip to test payments
   - [ ] Sign out works
   - [ ] Delete account works

---

## Step 3: Submit to App Store (30 minutes)

### Create App Listing:
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: CleanConnect
   - Primary Language: English
   - Bundle ID: `ca.thebighead.cleanconnect`
   - SKU: `cleanconnect-ios`

### Add App Information:
- Subtitle: "Clean India Together"
- Category: Social Networking
- Privacy Policy URL: `https://thebighead.ca/CleanConnect/privacy`
- Support URL: `https://thebighead.ca/CleanConnect/support`

### Upload Screenshots:
You need screenshots for:
- 6.7" iPhone (1290 x 2796 px) - iPhone 15 Pro Max
- 6.5" iPhone (1284 x 2778 px) - iPhone 14 Plus
- 5.5" iPhone (1242 x 2208 px) - iPhone 8 Plus

### App Privacy Questionnaire:
When asked "Does your app collect data?":
- Select: Yes
- Data types: Name, Email, Photos, Location, Payment Info
- Linked to user: Yes
- Used for tracking: No

### Submit for Review:
1. In Xcode: Product → Archive
2. Click Distribute App → App Store Connect
3. Back in App Store Connect, select the build
4. Click Submit for Review

---

## Quick Reference

| Item | Value |
|------|-------|
| Bundle ID | `ca.thebighead.cleanconnect` |
| Team ID | F385ZL83XQ |
| Firebase Project | cleanconnect-b7c67 |
| Webhook URL | `https://us-central1-cleanconnect-b7c67.cloudfunctions.net/stripeWebhook` |
| Platform Fee | 7% (creator gets 93%) |
| Privacy Policy | `https://thebighead.ca/CleanConnect/privacy` |
| Terms | `https://thebighead.ca/CleanConnect/terms` |
| Support | `https://thebighead.ca/CleanConnect/support` |
