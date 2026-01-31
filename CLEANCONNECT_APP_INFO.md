# CleanConnect - Complete App Documentation

*Last Updated: January 30, 2025*

---

## App Overview

| Field | Value |
|-------|-------|
| **App Name** | CleanConnect |
| **Subtitle** | Clean India Together |
| **Bundle ID** | com.cleanconnect.app |
| **Version** | 1.0.0 |
| **Build** | 1 |
| **Category** | Lifestyle (Primary), Social Networking (Secondary) |
| **Age Rating** | 4+ |
| **Copyright** | © 2025 The Big Head |
| **Developer** | The Big Head |
| **Minimum iOS** | iOS 17.0 |
| **Swift Version** | 5.0 |

---

## App Description

CleanConnect is a gamified social platform for environmental cleanup activities, targeting India. The app enables users to share cleanup efforts with video proof, receive tips from the community, and organize group cleanup events.

### Core Features

| Feature | Description |
|---------|-------------|
| **Video-First Posts** | Users post cleanup efforts with YouTube/Instagram video proof |
| **Community Voting** | Reddit-style upvote/downvote system |
| **Tipping System** | Send/receive tips via Stripe (7% platform fee, 93% to creator) |
| **Leaderboards** | State/district-level rankings by points |
| **Community Events** | Create/join cleanup gatherings with RSVP |
| **Verification Badges** | Verified, Video Proof, Community Verified, Unverified |
| **All India Coverage** | 700+ states and districts supported |

---

## Contact & URLs

| Type | URL |
|------|-----|
| **Support Email** | info@thebighead.ca |
| **Website** | https://thebighead.ca |
| **Privacy Policy** | https://thebighead.ca/cleanconnect/privacy |
| **Terms of Service** | https://thebighead.ca/cleanconnect/terms |
| **Support Page** | https://thebighead.ca/cleanconnect/support |

---

## Backend Services

### Firebase Project
- **Project ID**: cleanconnect-b7c67
- **Console**: https://console.firebase.google.com/project/cleanconnect-b7c67

### Cloud Functions Deployed (11 functions)
| Function | Purpose |
|----------|---------|
| `voteOnPost` | Handle upvotes/downvotes |
| `getUserVote` | Get user's vote on a post |
| `deletePost` | Delete a post (owner only) |
| `deleteComment` | Delete a comment (owner only) |
| `recalculateUserStats` | Recalculate user points/stats |
| `getFeedPosts` | Fetch feed with sorting/filtering |
| `createConnectAccount` | Create Stripe Connect account |
| `checkConnectStatus` | Check Stripe account status |
| `createTipPaymentIntent` | Create payment intent for tips |
| `stripeWebhook` | Handle Stripe webhook events |
| `createDashboardLink` | Create Stripe dashboard link |

### Stripe Configuration
- **Webhook URL**: `https://us-central1-cleanconnect-b7c67.cloudfunctions.net/stripeWebhook`
- **Events**: `payment_intent.succeeded`, `payment_intent.payment_failed`, `account.updated`

---

## App Store Listing Content

### Keywords (100 characters)
```
cleanup,swachh bharat,clean india,environment,garbage,waste,tips,earn,volunteer,green
```

### Promotional Text
```
Make a difference in your neighborhood. Document your cleanup efforts with video proof and inspire others across India.
```

### Description
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
Join or organize cleanup events in your area.

ALL INDIA COVERAGE
Every state and district supported.

#SwachhBharat #CleanIndia
```

### What's New (Version 1.0.0)
```
Initial release of CleanConnect - India's cleanup community platform!

• Post cleanup videos with YouTube/Instagram links
• Upvote and downvote posts
• Send and receive tips
• Join community cleanup events
• Climb the leaderboard
• Filter by state and district
```

### Review Notes (For Apple Reviewer)
```
To test: Sign in with Google/Apple, create a post with YouTube link, upvote posts, check leaderboard.
Payment features require Stripe Connect setup.
No test account needed.
```

---

## Technical Architecture

### Project Structure
```
CleanConnect/
├── App/
│   ├── CleanConnectApp.swift      # Main entry point
│   ├── ContentView.swift          # Tab-based navigation
│   └── AppConfiguration.swift     # App configuration
├── Models/
│   ├── User.swift                 # User model
│   ├── Post.swift                 # Posts, Comments, Tips
│   ├── Gathering.swift            # Events, RSVPs
│   ├── CleaningCompany.swift      # Companies (placeholder)
│   ├── CleanupJob.swift           # Cleanup jobs
│   └── Leaderboard.swift          # Rankings
├── Views/
│   ├── Auth/                      # Login/Registration
│   ├── Feed/                      # Post feed, create, detail
│   ├── Gatherings/                # Events list, create, detail
│   ├── Companies/                 # Company list, detail
│   ├── Profile/                   # Profile, settings
│   ├── Leaderboards/              # Leaderboard views
│   ├── Badges/                    # Badge views
│   ├── Impact/                    # Impact dashboard
│   ├── Map/                       # Pollution map
│   └── Discover/                  # Discovery view
├── ViewModels/
│   ├── FeedViewModel.swift
│   ├── PostDetailViewModel.swift
│   ├── GatheringsViewModel.swift
│   ├── LeaderboardViewModel.swift
│   └── CompaniesViewModel.swift
├── Services/
│   ├── AuthManager.swift          # Authentication state
│   ├── AuthenticationService.swift # Firebase Auth
│   ├── FirestoreService.swift     # Firestore operations
│   ├── CloudFunctionsService.swift # Cloud Functions
│   ├── StripeService.swift        # Stripe payments
│   ├── UserState.swift            # User session
│   ├── PostService.swift          # Post operations
│   ├── GatheringService.swift     # Event operations
│   ├── BookingService.swift       # Booking operations
│   ├── PaymentService.swift       # Payment handling
│   ├── LocalDataManager.swift     # Local storage
│   ├── StorageService.swift       # File storage
│   ├── KeychainManager.swift      # Secure storage
│   └── WatchSyncService.swift     # Apple Watch sync
├── Components/
│   ├── CachedAsyncImage.swift     # Image caching
│   ├── SkeletonView.swift         # Loading skeletons
│   ├── InputValidation.swift      # Input validators
│   ├── AccessibilityHelpers.swift # Accessibility
│   ├── ConfettiView.swift         # Celebrations
│   └── OnboardingView.swift       # Onboarding
├── Utils/
│   ├── Constants.swift            # Indian states, config
│   ├── LocationManager.swift      # Location services
│   └── LocalizationManager.swift  # Localization
└── Extensions/
    └── Extensions.swift           # Color, Date, String helpers
```

### Design System (Indian Tricolor Theme)
| Color | Hex | Usage |
|-------|-----|-------|
| Saffron | `#FF9933` | Primary accent |
| India Green | `#138808` | Secondary accent |
| Tip Gold | `#F59E0B` | Tips/rewards |
| AI Warning | `#8B5CF6` | AI warning purple |
| Success Green | `#22C55E` | Success states |
| Verified Blue | `#3B82F6` | Verified badges |

---

## Data Models

### Post
| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier |
| userId | String | Creator's user ID |
| description | String | Post description |
| videoProofURL | String? | YouTube/Instagram link |
| wasteCollectedKg | Double | Waste collected in kg |
| state, district | String | Location |
| communityVotes | Int | Upvotes |
| communityDownvotes | Int | Downvotes |
| tipsReceived | Int | Total tips in INR |
| verificationBadge | Enum | verified, videoProof, communityVerified, unverified |

### User
| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier |
| displayName | String | User's name |
| state, district | String | Location |
| totalPoints | Int | Points earned |
| totalWasteKg | Double | Total waste collected |
| level | Int | User level (1-10+) |
| badges | [String] | Earned badges |

### Gathering (Event)
| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique identifier |
| title | String | Event title |
| eventDate | Date | Event date/time |
| state, district | String | Location |
| attendeesCount | Int | Number of RSVPs |
| whatsappGroupLink | String? | WhatsApp group URL |

---

## Payment System

| Item | Value |
|------|-------|
| Platform Fee | 7% |
| Creator Share | 93% |
| Minimum Tip | ₹10 |
| Maximum Tip | ₹10,000 |
| Payment Provider | Stripe |
| Payout Method | Stripe Connect |

---

## Feed Sorting & Filtering

### Sort Options
| Option | Description |
|--------|-------------|
| Hot | Trending posts (votes + recency) |
| New | Newest posts first |
| Top | Highest voted posts |
| Most Tipped | Posts with most tips |

### Time Filters
- Day, Week, Month, Year, All Time

### Location Filters
- All India
- My State
- My District

---

## Gamification System

### Points
| Action | Points |
|--------|--------|
| Post Created | 50 |
| Post with Video | 75 |
| Event Organized | 100 |
| Event Attended | 25 |
| Per ₹10 Tip Received | 1 |

### Levels
| Level | Title |
|-------|-------|
| 1 | Beginner |
| 2 | Cleaner |
| 3 | Warrior |
| 4 | Champion |
| 5 | Hero |
| 6+ | Legend |

### Verification Badges
| Badge | Requirements |
|-------|--------------|
| Verified | Video proof + 5+ upvotes + <2 downvotes |
| Video Proof | Has video proof |
| Community Verified | 10+ upvotes (no video) |
| Unverified | Default |

---

## Screenshot Requirements

### iPhone Sizes
| Device | Resolution |
|--------|------------|
| 6.7" (iPhone 15 Pro Max) | 1290 × 2796 px |
| 6.5" (iPhone 11 Pro Max) | 1242 × 2688 px |

### Recommended Screenshots
1. Feed - Show posts with upvotes and video badges
2. Create Post - Show video link input
3. Post Detail - Show map and comments
4. Leaderboard - Show top cleaners
5. Profile - Show user stats

---

## Useful Commands

```bash
# Check Firebase function logs
npx firebase functions:log

# Redeploy functions
npx firebase deploy --only functions

# Redeploy Firestore rules
npx firebase deploy --only firestore:rules

# Build app in Xcode
# Product → Archive → Distribute App
```

---

## Important URLs

| Service | URL |
|---------|-----|
| Firebase Console | https://console.firebase.google.com/project/cleanconnect-b7c67 |
| Stripe Dashboard | https://dashboard.stripe.com |
| App Store Connect | https://appstoreconnect.apple.com |

---

## App Submission Status

| Phase | Status |
|-------|--------|
| Developer Account | ✅ Complete |
| App Icon | ⬜ Needed |
| Screenshots | ⬜ Needed |
| Privacy/Terms/Support Pages | ✅ Created (need hosting) |
| Firebase Backend | ✅ Deployed |
| Stripe Configuration | ✅ Configured |
| Xcode Build | ✅ Succeeds |
| App Store Connect Setup | ⬜ Not Started |
| Submit for Review | ⬜ Not Started |

---

## Post-Launch Checklist

**Week 1:**
- Monitor crash reports in Xcode Organizer
- Respond to App Store reviews
- Check Firebase logs for errors

**Future (v2):**
- Cleanup Bounties (paid jobs)
- Push notifications
- Following system
- Hindi localization

---

*CleanConnect - Clean India Together*
