# CleanConnect iOS App - Project Plan

## Project Overview
CleanConnect is a gamified social platform for environmental cleanup activities, targeting India. The app enables users to share cleanup efforts, organize community events, and connect with professional cleaning services.

## Current State (v1.0.0 - Local/Offline Mode)

### Completed Features
- **Authentication**: Local user creation with name and location (state/district)
- **Feed**: View and create cleanup posts with before/after photos
- **Events**: Browse and create community cleanup gatherings
- **Companies**: View cleaning service providers
- **Profile**: User stats, badges, and level progression
- **Gamification**: Points, levels, badges, and leaderboards

### Technical Architecture
```
CleanConnect/
├── App/
│   ├── CleanConnectApp.swift      # Main entry point
│   └── ContentView.swift          # Tab-based navigation
├── Models/
│   ├── User.swift                 # User, Badge, Experience levels
│   ├── Post.swift                 # Posts, Comments, Tips
│   ├── Gathering.swift            # Events, RSVPs, Supplies
│   ├── CleaningCompany.swift      # Companies, Services, Bookings
│   └── Leaderboard.swift          # Rankings, Campaigns, Squads
├── Views/
│   ├── Auth/AuthView.swift        # Login/Registration
│   ├── Feed/                      # Post feed, create, detail
│   ├── Gatherings/                # Events list, create, detail
│   ├── Companies/                 # Company list, detail, booking
│   └── Profile/                   # Profile, settings, edit
├── Services/
│   ├── AuthManager.swift          # Authentication state
│   ├── UserState.swift            # User session management
│   ├── LocalDataManager.swift     # JSON-based local storage
│   ├── UserService.swift          # User operations
│   ├── PostService.swift          # Post operations
│   ├── GatheringService.swift     # Event operations
│   ├── BookingService.swift       # Booking operations
│   ├── PaymentService.swift       # Payment placeholders
│   └── ViewModels.swift           # View models for all screens
├── Utils/
│   ├── Constants.swift            # Indian states, config
│   └── LocationManager.swift      # Location services
├── Extensions/
│   └── Extensions.swift           # Color, Date, String helpers
└── Assets.xcassets/               # App icons, colors
```

---

## Development Roadmap

### Phase 1: Foundation (Current)
**Status: Complete**
- [x] Project structure setup
- [x] Local storage implementation
- [x] Offline authentication
- [x] Sample data for demo
- [x] All UI screens functional

### Phase 2: Core Polish
**Estimated: 2-3 weeks**
- [ ] Image picker integration (camera + gallery)
- [ ] Location services for geotagging posts
- [ ] Push notification setup (local)
- [ ] App icon and launch screen
- [ ] Dark mode support
- [ ] Hindi localization

### Phase 3: Backend Integration
**Estimated: 3-4 weeks**
- [ ] Firebase/Supabase setup
- [ ] Real-time data sync
- [ ] Cloud image storage
- [ ] User authentication (Google, Apple, Phone OTP)
- [ ] Push notifications (FCM)

### Phase 4: Payments & Monetization
**Estimated: 2-3 weeks**
- [ ] Razorpay integration for tips
- [ ] UPI deep linking (BHIM, GPay, PhonePe)
- [ ] Service booking payments
- [ ] Wallet system
- [ ] GST compliance

### Phase 5: Advanced Features
**Estimated: 4-6 weeks**
- [ ] AI-based cleanup verification
- [ ] Squad/Team features
- [ ] Campaigns and challenges
- [ ] Company dashboard
- [ ] Admin panel
- [ ] Analytics integration

---

## India-Specific Features

### Already Implemented
- All 29 states and 8 UTs with districts
- INR currency formatting
- 18% GST calculations
- UPI payment limits (₹1,00,000)
- Indian mobile number validation

### Planned
- Regional language support (Hindi, Tamil, Telugu, etc.)
- Swachh Bharat Abhiyan campaign integration
- Government scheme awareness
- NGO partnerships
- WhatsApp sharing
- Aadhaar-based KYC for payouts

---

## Technical Requirements

### Xcode Setup
1. Open `CleanConnect.xcodeproj` in Xcode 15+
2. Select your development team
3. Change bundle identifier if needed
4. Build and run on iOS 17+ device/simulator

### Dependencies (To Add via SPM)
```
- Firebase (when ready for backend)
- GoogleSignIn
- Razorpay SDK
- Kingfisher (image caching)
- Lottie (animations)
```

### Build Settings
- iOS Deployment Target: 17.0
- Swift Language Version: 5.9
- Bundle Identifier: com.cleanconnect.app

---

## Testing Strategy

### Unit Tests
- Model encoding/decoding
- Service layer operations
- Points calculation
- Level progression

### UI Tests
- Authentication flow
- Post creation
- Event RSVP
- Booking flow

### Manual Testing
- All Indian states/districts
- Payment flows (when integrated)
- Location permissions
- Camera/Photo permissions

---

## App Store Preparation

### Required
- [ ] App icon (1024x1024)
- [ ] Screenshots for all device sizes
- [ ] App description (English + Hindi)
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Support email/URL

### Categories
- Primary: Social Networking
- Secondary: Lifestyle

### Age Rating
- 4+ (no objectionable content)

---

## Contact & Support
- Email: support@cleanconnect.app
- Website: https://cleanconnect.app
