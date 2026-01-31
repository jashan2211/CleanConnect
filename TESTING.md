# CleanConnect - Complete Testing Guide

*Last Updated: January 30, 2025*

This document covers all testable features and user flows in the CleanConnect app.

---

## Test Environment Setup

### Prerequisites
- Xcode 15.2+
- iOS 17.0+ Simulator or Device
- Apple Developer Account (for device testing)
- Internet connection (for Firebase/Stripe features)

### Build & Run
1. Open `CleanConnect.xcodeproj` in Xcode
2. Select scheme: **CleanConnect**
3. Select target: **iPhone 15 Pro** (or any iOS 17+ simulator)
4. Press **Cmd + R** to build and run

---

## 1. Authentication Tests

### 1.1 Sign Up Flow
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Google Sign In | Tap "Continue with Google" → Select account | User signed in, redirected to Feed |
| Apple Sign In | Tap "Continue with Apple" → Authenticate | User signed in, redirected to Feed |
| Cancel Sign In | Start sign in → Cancel | Returns to auth screen, no crash |

### 1.2 Sign Out
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Sign Out | Profile → Settings → Sign Out | Returns to auth screen |
| Sign Out Confirmation | Tap Sign Out → Confirm | User logged out, data cleared |

### 1.3 Session Persistence
| Test | Steps | Expected Result |
|------|-------|-----------------|
| App Restart | Sign in → Close app → Reopen | User still signed in |
| Background/Foreground | Sign in → Background app → Return | Session maintained |

---

## 2. Feed Tests

### 2.1 Feed Loading
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Initial Load | Open app (signed in) | Feed loads with posts |
| Pull to Refresh | Pull down on feed | Feed refreshes, new posts appear |
| Skeleton Loading | Load feed on slow connection | Skeleton placeholders shown |
| Empty State | Filter to area with no posts | Empty state message displayed |

### 2.2 Sorting Options
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Sort by Hot | Tap sort → Select "Hot" | Trending posts shown first |
| Sort by New | Tap sort → Select "New" | Newest posts shown first |
| Sort by Top | Tap sort → Select "Top" | Highest voted posts first |
| Sort by Most Tipped | Tap sort → Select "Most Tipped" | Posts with most tips first |

### 2.3 Time Filters
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Filter: Today | Select time filter → "Day" | Only posts from last 24 hours |
| Filter: This Week | Select time filter → "Week" | Only posts from last 7 days |
| Filter: This Month | Select time filter → "Month" | Only posts from last 30 days |
| Filter: This Year | Select time filter → "Year" | Only posts from last 365 days |
| Filter: All Time | Select time filter → "All" | All posts shown |

### 2.4 Location Filters
| Test | Steps | Expected Result |
|------|-------|-----------------|
| All India | Select location → "All India" | Posts from all states shown |
| My State | Select location → "My State" | Only posts from user's state |
| My District | Select location → "My District" | Only posts from user's district |

### 2.5 Post Interactions (Feed)
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Upvote Post | Tap upvote arrow | Vote count increases, arrow highlighted |
| Downvote Post | Tap downvote arrow | Vote count decreases, arrow highlighted |
| Remove Vote | Tap same vote button again | Vote removed, count adjusted |
| Change Vote | Upvote → Tap downvote | Vote switches, count adjusts by 2 |
| Tap Post | Tap on post card | Opens post detail view |

---

## 3. Create Post Tests

### 3.1 Post Creation Flow
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Create | Tap "+" button in feed | Create post sheet opens |
| Add Video Link | Paste YouTube/Instagram URL | Link accepted, preview shown |
| Invalid Video URL | Enter non-video URL | Error message shown |
| Add Description | Type description text | Text entered, character count shown |
| Select Location | Choose state and district | Location dropdowns work |
| Submit Post | Fill all fields → Tap "Post" | Post created, appears in feed |
| Cancel Create | Tap cancel/swipe down | Sheet dismissed, no post created |

### 3.2 Video URL Validation
| Test | Steps | Expected Result |
|------|-------|-----------------|
| YouTube URL | Enter `youtube.com/...` | Accepted |
| YouTube Shorts | Enter `youtube.com/shorts/...` | Accepted |
| Instagram Reel | Enter `instagram.com/reel/...` | Accepted |
| Invalid URL | Enter `google.com` | Rejected with error |
| Empty URL | Leave video field empty | Post created without video badge |

### 3.3 Location Selection
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Select State | Tap state dropdown → Select | District dropdown populates |
| Select District | Tap district dropdown → Select | District selected |
| All States Available | Scroll through states | All 29 states + 8 UTs present |
| Districts Match State | Select different states | Districts update correctly |

---

## 4. Post Detail Tests

### 4.1 Post Detail View
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Detail | Tap post in feed | Detail view opens |
| View Video | Tap video proof link | Opens YouTube/Instagram |
| View Location | Scroll to map section | Map shows post location |
| Get Directions | Tap "Directions" on map | Opens Maps app with directions |
| Back Navigation | Tap back button | Returns to feed |

### 4.2 Voting in Detail
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Upvote | Tap upvote in detail | Vote count increases |
| Downvote | Tap downvote in detail | Vote count decreases |
| Vote Persists | Vote → Go back → Return | Vote still visible |

### 4.3 Comments
| Test | Steps | Expected Result |
|------|-------|-----------------|
| View Comments | Scroll to comments section | Comments displayed |
| Add Comment | Type comment → Submit | Comment appears in list |
| Delete Own Comment | Tap trash icon on own comment | Comment deleted |
| Cannot Delete Others | View other user's comment | No delete option shown |

### 4.4 Post Deletion
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Delete Own Post | Open own post → Tap delete | Confirmation dialog shown |
| Confirm Delete | Tap "Delete" in dialog | Post deleted, returns to feed |
| Cancel Delete | Tap "Cancel" in dialog | Post not deleted |
| Cannot Delete Others | View other user's post | No delete option shown |

---

## 5. Tipping Tests

### 5.1 Tip Flow
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Tip Sheet | Tap "Tip" on post | Tip sheet opens |
| Quick Amount ₹10 | Tap ₹10 button | Amount set to ₹10 |
| Quick Amount ₹50 | Tap ₹50 button | Amount set to ₹50 |
| Quick Amount ₹100 | Tap ₹100 button | Amount set to ₹100 |
| Custom Amount | Enter custom amount | Amount accepted |
| Fee Display | Select any amount | Shows 7% fee breakdown |
| Creator Share | Select any amount | Shows 93% to creator |

### 5.2 Payment Processing
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Test Card Payment | Enter `4242 4242 4242 4242` | Payment succeeds |
| Declined Card | Enter `4000 0000 0000 0002` | Payment declined message |
| Cancel Payment | Start payment → Cancel | Returns to tip sheet |
| Success Confirmation | Complete payment | Success message shown |

### 5.3 Tip Validation
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Below Minimum | Enter ₹5 | Error: minimum ₹10 |
| Above Maximum | Enter ₹15,000 | Error: maximum ₹10,000 |
| Invalid Amount | Enter letters | Input rejected |
| Zero Amount | Enter 0 | Error message shown |

---

## 6. Leaderboard Tests

### 6.1 Leaderboard View
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Leaderboard | Tap leaderboard tab | Leaderboard loads |
| View Rankings | Scroll through list | Users ranked by points |
| User Position | Find current user | Highlighted in list |

### 6.2 Leaderboard Filters
| Test | Steps | Expected Result |
|------|-------|-----------------|
| All India | Select "All India" | National rankings shown |
| My State | Select "My State" | State rankings shown |
| My District | Select "My District" | District rankings shown |

---

## 7. Events (Gatherings) Tests

### 7.1 Events List
| Test | Steps | Expected Result |
|------|-------|-----------------|
| View Events | Tap events tab | Events list loads |
| Pull to Refresh | Pull down on list | Events refresh |
| Empty State | No events available | Empty state message |

### 7.2 Event Detail
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Event | Tap event card | Event detail opens |
| View Date/Time | Check event info | Date and time displayed |
| View Location | Check event info | State and district shown |
| View Attendees | Check attendee count | Number displayed |
| Join WhatsApp | Tap WhatsApp link | Opens WhatsApp group |

### 7.3 RSVP
| Test | Steps | Expected Result |
|------|-------|-----------------|
| RSVP to Event | Tap "Join" button | RSVP confirmed |
| Cancel RSVP | Tap "Cancel RSVP" | RSVP removed |
| Attendee Count | RSVP to event | Count increases |

### 7.4 Create Event
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Create | Tap "+" in events | Create event sheet opens |
| Enter Title | Type event title | Title entered |
| Set Date | Pick date and time | Date selected |
| Set Location | Choose state/district | Location set |
| Add WhatsApp Link | Enter group URL | Link saved |
| Create Event | Fill all → Submit | Event created |
| Cancel Create | Tap cancel | Sheet dismissed |

---

## 8. Profile Tests

### 8.1 Profile View
| Test | Steps | Expected Result |
|------|-------|-----------------|
| View Profile | Tap profile tab | Profile loads |
| View Stats | Check stats section | Points, waste, posts shown |
| View Level | Check level display | Current level and title |
| View Badges | Scroll to badges | Earned badges displayed |

### 8.2 Edit Profile
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Edit | Tap "Edit Profile" | Edit screen opens |
| Change Name | Edit display name | Name updated |
| Change Location | Select new state/district | Location updated |
| Save Changes | Tap "Save" | Changes persisted |
| Cancel Edit | Tap "Cancel" | Changes discarded |

### 8.3 Settings
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Settings | Tap settings gear | Settings screen opens |
| Toggle Notifications | Tap notification toggle | Setting changed |
| Privacy Settings | Check privacy options | Options available |
| Sign Out | Tap "Sign Out" | User logged out |

---

## 9. Map Features Tests

### 9.1 Post Location Map
| Test | Steps | Expected Result |
|------|-------|-----------------|
| View Map | Open post with location | Map preview shown |
| Tap Map | Tap on map preview | Full map view opens |
| Get Directions | Tap "Directions" | Opens Maps app |
| Map Pin | Check map | Pin at correct location |

### 9.2 Pollution Map (if available)
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Open Map | Navigate to map view | Map loads |
| View Hotspots | Check for markers | Pollution hotspots shown |
| Tap Hotspot | Tap on marker | Info popup displayed |

---

## 10. Verification Badge Tests

### 10.1 Badge Display
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Verified Badge | Post with video + 5 upvotes | Blue checkmark badge |
| Video Proof Badge | Post with video only | Green video badge |
| Community Verified | Post with 10+ upvotes (no video) | Orange community badge |
| Unverified | New post, no video | Gray question mark |

### 10.2 Badge Progression
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Earn Video Badge | Create post with video | Video proof badge shown |
| Earn Verified | Get 5+ upvotes on video post | Badge upgrades to verified |

---

## 11. Offline/Error Handling Tests

### 11.1 Network Errors
| Test | Steps | Expected Result |
|------|-------|-----------------|
| No Internet | Disable network → Use app | Error message shown |
| Slow Connection | Throttle network | Loading indicators work |
| Network Recovery | Lose connection → Restore | App recovers gracefully |

### 11.2 Error Messages
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Auth Error | Force auth failure | User-friendly error shown |
| Post Error | Force post creation failure | Error message displayed |
| Payment Error | Force payment failure | Clear error explanation |

---

## 12. UI/UX Tests

### 12.1 Device Compatibility
| Test | Device | Expected Result |
|------|--------|-----------------|
| iPhone SE | Smallest screen | UI fits, no truncation |
| iPhone 15 Pro | Standard size | UI displays correctly |
| iPhone 15 Pro Max | Largest screen | UI scales properly |

### 12.2 Dark Mode
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Enable Dark Mode | Settings → Dark Mode | App switches to dark theme |
| All Screens | Navigate through app | All screens support dark mode |
| Colors Readable | Check text/backgrounds | Sufficient contrast |

### 12.3 Dynamic Type
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Large Text | iOS Settings → Larger Text | App text scales |
| Extra Large | Maximum text size | UI remains usable |
| Small Text | Minimum text size | Text remains readable |

### 12.4 Accessibility
| Test | Steps | Expected Result |
|------|-------|-----------------|
| VoiceOver | Enable VoiceOver | All elements announced |
| Button Labels | Navigate with VoiceOver | Buttons have labels |
| Image Descriptions | Check images | Alt text provided |

---

## 13. Performance Tests

### 13.1 Launch Performance
| Test | Metric | Target |
|------|--------|--------|
| Cold Launch | Time to interactive | < 3 seconds |
| Warm Launch | Time to interactive | < 1 second |

### 13.2 Scrolling Performance
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Feed Scroll | Scroll through 50+ posts | Smooth 60fps |
| Comments Scroll | Scroll through 100+ comments | No jank |
| Leaderboard Scroll | Scroll through rankings | Smooth scrolling |

### 13.3 Memory
| Test | Steps | Expected Result |
|------|-------|-----------------|
| Long Session | Use app for 30+ minutes | No memory warnings |
| Image Heavy | View many posts with images | Memory stays stable |

---

## 14. Edge Cases

### 14.1 Input Edge Cases
| Test | Input | Expected Result |
|------|-------|-----------------|
| Empty Description | Submit empty post | Validation error |
| Very Long Text | 5000+ character description | Truncated or error |
| Special Characters | Emojis, Unicode | Handled correctly |
| SQL Injection | `'; DROP TABLE posts;--` | Safely escaped |
| XSS Attempt | `<script>alert('xss')</script>` | Rendered as text |

### 14.2 Data Edge Cases
| Test | Scenario | Expected Result |
|------|----------|-----------------|
| No Posts | New user, empty feed | Empty state shown |
| No Events | No events in area | Empty state shown |
| Zero Points | New user profile | Shows 0 points |
| Negative Votes | More downvotes than upvotes | Shows negative count |

---

## 15. Stripe Test Cards

| Card Number | Scenario |
|-------------|----------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 0002` | Card declined |
| `4000 0000 0000 9995` | Insufficient funds |
| `4000 0000 0000 0069` | Expired card |
| `4000 0000 0000 0127` | Incorrect CVC |

**Test Card Details:**
- Expiry: Any future date
- CVC: Any 3 digits
- ZIP: Any 5 digits

---

## Test Completion Checklist

### Critical Path (Must Pass)
- [ ] Google/Apple Sign In works
- [ ] Can create post with video
- [ ] Feed loads and displays posts
- [ ] Upvote/downvote works and persists
- [ ] Tip payment completes (test card)
- [ ] Leaderboard displays rankings
- [ ] Profile shows correct stats
- [ ] Sign out works

### Secondary Features
- [ ] All sort options work
- [ ] All time filters work
- [ ] All location filters work
- [ ] Events RSVP works
- [ ] Create event works
- [ ] Edit profile works
- [ ] Comments work
- [ ] Post deletion works

### Edge Cases
- [ ] Empty states display correctly
- [ ] Error messages are user-friendly
- [ ] Offline handling works
- [ ] Input validation works

---

## Bug Report Template

```
**Bug Title:** [Brief description]

**Steps to Reproduce:**
1.
2.
3.

**Expected Result:**

**Actual Result:**

**Device:** [iPhone model]
**iOS Version:** [Version]
**App Version:** [1.0.0]

**Screenshots/Video:** [Attach if applicable]
```

---

*Happy Testing!*
