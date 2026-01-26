// LocalizationManager.swift
// Multi-language support for CleanConnect
// Supports: English, Hindi, Tamil, Telugu, Marathi, Bengali, Gujarati, Kannada

import SwiftUI
import Observation

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case tamil = "ta"
    case telugu = "te"
    case marathi = "mr"
    case bengali = "bn"
    case gujarati = "gu"
    case kannada = "kn"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        case .tamil: return "தமிழ் (Tamil)"
        case .telugu: return "తెలుగు (Telugu)"
        case .marathi: return "मराठी (Marathi)"
        case .bengali: return "বাংলা (Bengali)"
        case .gujarati: return "ગુજરાતી (Gujarati)"
        case .kannada: return "ಕನ್ನಡ (Kannada)"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .marathi: return "मराठी"
        case .bengali: return "বাংলা"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        }
    }
}

// MARK: - Localization Keys

enum LocalizedKey: String {
    // Common
    case appName
    case loading
    case error
    case retry
    case cancel
    case done
    case save
    case delete
    case edit
    case share
    case settings

    // Tabs
    case tabEvents
    case tabFeed
    case tabDiscover
    case tabServices
    case tabProfile

    // Feed
    case feedTitle
    case createPost
    case wasteCollected
    case duration
    case points
    case likes
    case comments
    case sendTip
    case videoProof

    // Events
    case eventsTitle
    case upcomingEvents
    case ongoingEvents
    case pastEvents
    case createEvent
    case joinEvent
    case rsvp

    // Jobs
    case jobsTitle
    case cleanupJobs
    case createJob
    case claimJob
    case submitProof
    case jobCompleted
    case nearbyJobs
    case earnRewards

    // Impact
    case yourImpact
    case totalCollected
    case totalCleanups
    case streak
    case equivalent
    case plasticBottles
    case garbageBags
    case treesSaved
    case co2Saved

    // Profile
    case profile
    case editProfile
    case myPosts
    case myEvents
    case myBadges
    case achievements
    case level

    // Discover
    case discover
    case leaderboards
    case badges
    case pollutionMap
    case liveEvents
    case communityImpact

    // Authentication
    case signIn
    case signUp
    case signOut
    case phoneNumber
    case verifyOTP
    case welcome

    // Notifications
    case newTip
    case newComment
    case eventReminder
    case jobNearby
    case milestoneReached
}

// MARK: - Localization Manager

@MainActor
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            loadStrings()
        }
    }

    private var strings: [String: String] = [:]

    private init() {
        // Load saved language or default to English
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        } else {
            // Try to detect from device locale
            let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = AppLanguage(rawValue: deviceLang) ?? .english
        }
        loadStrings()
    }

    private func loadStrings() {
        strings = Self.allStrings[currentLanguage] ?? Self.allStrings[.english]!
    }

    func localized(_ key: LocalizedKey) -> String {
        strings[key.rawValue] ?? key.rawValue
    }

    func localized(_ key: String) -> String {
        strings[key] ?? key
    }

    // MARK: - All Strings

    private static let allStrings: [AppLanguage: [String: String]] = [
        .english: englishStrings,
        .hindi: hindiStrings,
        .tamil: tamilStrings,
        .telugu: teluguStrings,
        .marathi: marathiStrings,
        .bengali: bengaliStrings,
        .gujarati: gujaratiStrings,
        .kannada: kannadaStrings
    ]

    // MARK: - English Strings

    private static let englishStrings: [String: String] = [
        // Common
        "appName": "CleanConnect",
        "loading": "Loading...",
        "error": "Error",
        "retry": "Retry",
        "cancel": "Cancel",
        "done": "Done",
        "save": "Save",
        "delete": "Delete",
        "edit": "Edit",
        "share": "Share",
        "settings": "Settings",

        // Tabs
        "tabEvents": "Events",
        "tabFeed": "Feed",
        "tabDiscover": "Discover",
        "tabServices": "Services",
        "tabProfile": "Profile",

        // Feed
        "feedTitle": "Feed",
        "createPost": "Create Post",
        "wasteCollected": "Waste Collected",
        "duration": "Duration",
        "points": "Points",
        "likes": "Likes",
        "comments": "Comments",
        "sendTip": "Send Tip",
        "videoProof": "Video Proof",

        // Events
        "eventsTitle": "Events",
        "upcomingEvents": "Upcoming Events",
        "ongoingEvents": "Ongoing Events",
        "pastEvents": "Past Events",
        "createEvent": "Create Event",
        "joinEvent": "Join Event",
        "rsvp": "RSVP",

        // Jobs
        "jobsTitle": "Cleanup Jobs",
        "cleanupJobs": "Cleanup Jobs",
        "createJob": "Create Job",
        "claimJob": "Claim Job",
        "submitProof": "Submit Proof",
        "jobCompleted": "Job Completed",
        "nearbyJobs": "Nearby Jobs",
        "earnRewards": "Earn Rewards",

        // Impact
        "yourImpact": "Your Impact",
        "totalCollected": "Total Collected",
        "totalCleanups": "Total Cleanups",
        "streak": "Streak",
        "equivalent": "Equivalent to",
        "plasticBottles": "Plastic Bottles",
        "garbageBags": "Garbage Bags",
        "treesSaved": "Trees Worth of CO2",
        "co2Saved": "CO2 Saved",

        // Profile
        "profile": "Profile",
        "editProfile": "Edit Profile",
        "myPosts": "My Posts",
        "myEvents": "My Events",
        "myBadges": "My Badges",
        "achievements": "Achievements",
        "level": "Level",

        // Discover
        "discover": "Discover",
        "leaderboards": "Leaderboards",
        "badges": "Badges",
        "pollutionMap": "Pollution Map",
        "liveEvents": "Live Events",
        "communityImpact": "Community Impact",

        // Auth
        "signIn": "Sign In",
        "signUp": "Sign Up",
        "signOut": "Sign Out",
        "phoneNumber": "Phone Number",
        "verifyOTP": "Verify OTP",
        "welcome": "Welcome",

        // Notifications
        "newTip": "New Tip Received",
        "newComment": "New Comment",
        "eventReminder": "Event Reminder",
        "jobNearby": "Job Nearby",
        "milestoneReached": "Milestone Reached"
    ]

    // MARK: - Hindi Strings

    private static let hindiStrings: [String: String] = [
        // Common
        "appName": "क्लीनकनेक्ट",
        "loading": "लोड हो रहा है...",
        "error": "त्रुटि",
        "retry": "पुनः प्रयास करें",
        "cancel": "रद्द करें",
        "done": "हो गया",
        "save": "सहेजें",
        "delete": "हटाएं",
        "edit": "संपादित करें",
        "share": "साझा करें",
        "settings": "सेटिंग्स",

        // Tabs
        "tabEvents": "इवेंट्स",
        "tabFeed": "फ़ीड",
        "tabDiscover": "खोजें",
        "tabServices": "सेवाएं",
        "tabProfile": "प्रोफ़ाइल",

        // Feed
        "feedTitle": "फ़ीड",
        "createPost": "पोस्ट बनाएं",
        "wasteCollected": "एकत्रित कचरा",
        "duration": "अवधि",
        "points": "अंक",
        "likes": "पसंद",
        "comments": "टिप्पणियाँ",
        "sendTip": "टिप भेजें",
        "videoProof": "वीडियो प्रमाण",

        // Events
        "eventsTitle": "इवेंट्स",
        "upcomingEvents": "आगामी इवेंट्स",
        "ongoingEvents": "चल रहे इवेंट्स",
        "pastEvents": "पिछले इवेंट्स",
        "createEvent": "इवेंट बनाएं",
        "joinEvent": "इवेंट में शामिल हों",
        "rsvp": "RSVP",

        // Jobs
        "jobsTitle": "सफाई कार्य",
        "cleanupJobs": "सफाई कार्य",
        "createJob": "कार्य बनाएं",
        "claimJob": "कार्य लें",
        "submitProof": "प्रमाण जमा करें",
        "jobCompleted": "कार्य पूर्ण",
        "nearbyJobs": "पास के कार्य",
        "earnRewards": "पुरस्कार कमाएं",

        // Impact
        "yourImpact": "आपका प्रभाव",
        "totalCollected": "कुल संग्रह",
        "totalCleanups": "कुल सफाई",
        "streak": "लगातार दिन",
        "equivalent": "के बराबर",
        "plasticBottles": "प्लास्टिक बोतलें",
        "garbageBags": "कूड़े के थैले",
        "treesSaved": "पेड़ों के बराबर CO2",
        "co2Saved": "बचाई गई CO2",

        // Profile
        "profile": "प्रोफ़ाइल",
        "editProfile": "प्रोफ़ाइल संपादित करें",
        "myPosts": "मेरी पोस्ट",
        "myEvents": "मेरे इवेंट्स",
        "myBadges": "मेरे बैज",
        "achievements": "उपलब्धियां",
        "level": "स्तर",

        // Discover
        "discover": "खोजें",
        "leaderboards": "लीडरबोर्ड",
        "badges": "बैज",
        "pollutionMap": "प्रदूषण मानचित्र",
        "liveEvents": "लाइव इवेंट्स",
        "communityImpact": "समुदाय प्रभाव",

        // Auth
        "signIn": "साइन इन करें",
        "signUp": "साइन अप करें",
        "signOut": "साइन आउट करें",
        "phoneNumber": "फोन नंबर",
        "verifyOTP": "OTP सत्यापित करें",
        "welcome": "स्वागत है",

        // Notifications
        "newTip": "नई टिप मिली",
        "newComment": "नई टिप्पणी",
        "eventReminder": "इवेंट रिमाइंडर",
        "jobNearby": "पास में कार्य",
        "milestoneReached": "मील का पत्थर पहुंचा"
    ]

    // MARK: - Tamil Strings

    private static let tamilStrings: [String: String] = [
        "appName": "க்ளீன்கனெக்ட்",
        "loading": "ஏற்றுகிறது...",
        "error": "பிழை",
        "retry": "மீண்டும் முயற்சிக்கவும்",
        "cancel": "ரத்து செய்",
        "done": "முடிந்தது",
        "tabEvents": "நிகழ்வுகள்",
        "tabFeed": "பீட்",
        "tabDiscover": "கண்டறி",
        "tabProfile": "சுயவிவரம்",
        "yourImpact": "உங்கள் தாக்கம்",
        "totalCollected": "மொத்த சேகரிப்பு",
        "cleanupJobs": "சுத்தம் செய்யும் வேலைகள்",
        "signIn": "உள்நுழைக",
        "welcome": "வரவேற்கிறோம்"
    ]

    // MARK: - Telugu Strings

    private static let teluguStrings: [String: String] = [
        "appName": "క్లీన్‌కనెక్ట్",
        "loading": "లోడ్ అవుతోంది...",
        "error": "లోపం",
        "retry": "మళ్ళీ ప్రయత్నించండి",
        "cancel": "రద్దు చేయి",
        "done": "పూర్తయింది",
        "tabEvents": "ఈవెంట్లు",
        "tabFeed": "ఫీడ్",
        "tabDiscover": "కనుగొను",
        "tabProfile": "ప్రొఫైల్",
        "yourImpact": "మీ ప్రభావం",
        "totalCollected": "మొత్తం సేకరించినది",
        "cleanupJobs": "శుభ్రపరిచే పనులు",
        "signIn": "సైన్ ఇన్",
        "welcome": "స్వాగతం"
    ]

    // MARK: - Marathi Strings

    private static let marathiStrings: [String: String] = [
        "appName": "क्लीनकनेक्ट",
        "loading": "लोड होत आहे...",
        "error": "त्रुटी",
        "retry": "पुन्हा प्रयत्न करा",
        "cancel": "रद्द करा",
        "done": "झाले",
        "tabEvents": "कार्यक्रम",
        "tabFeed": "फीड",
        "tabDiscover": "शोधा",
        "tabProfile": "प्रोफाइल",
        "yourImpact": "तुमचा प्रभाव",
        "totalCollected": "एकूण संकलन",
        "cleanupJobs": "स्वच्छता कामे",
        "signIn": "साइन इन करा",
        "welcome": "स्वागत आहे"
    ]

    // MARK: - Bengali Strings

    private static let bengaliStrings: [String: String] = [
        "appName": "ক্লিনকানেক্ট",
        "loading": "লোড হচ্ছে...",
        "error": "ত্রুটি",
        "retry": "আবার চেষ্টা করুন",
        "cancel": "বাতিল করুন",
        "done": "সম্পন্ন",
        "tabEvents": "ইভেন্ট",
        "tabFeed": "ফিড",
        "tabDiscover": "অন্বেষণ",
        "tabProfile": "প্রোফাইল",
        "yourImpact": "আপনার প্রভাব",
        "totalCollected": "মোট সংগ্রহ",
        "cleanupJobs": "পরিষ্কার কাজ",
        "signIn": "সাইন ইন",
        "welcome": "স্বাগতম"
    ]

    // MARK: - Gujarati Strings

    private static let gujaratiStrings: [String: String] = [
        "appName": "ક્લીનકનેક્ટ",
        "loading": "લોડ થઈ રહ્યું છે...",
        "error": "ભૂલ",
        "retry": "ફરીથી પ્રયાસ કરો",
        "cancel": "રદ કરો",
        "done": "પૂર્ણ",
        "tabEvents": "ઇવેન્ટ્સ",
        "tabFeed": "ફીડ",
        "tabDiscover": "શોધો",
        "tabProfile": "પ્રોફાઇલ",
        "yourImpact": "તમારી અસર",
        "totalCollected": "કુલ સંગ્રહ",
        "cleanupJobs": "સફાઈ કામ",
        "signIn": "સાઇન ઇન",
        "welcome": "સ્વાગત છે"
    ]

    // MARK: - Kannada Strings

    private static let kannadaStrings: [String: String] = [
        "appName": "ಕ್ಲೀನ್‌ಕನೆಕ್ಟ್",
        "loading": "ಲೋಡ್ ಆಗುತ್ತಿದೆ...",
        "error": "ದೋಷ",
        "retry": "ಮರುಪ್ರಯತ್ನಿಸಿ",
        "cancel": "ರದ್ದುಮಾಡಿ",
        "done": "ಮುಗಿದಿದೆ",
        "tabEvents": "ಈವೆಂಟ್‌ಗಳು",
        "tabFeed": "ಫೀಡ್",
        "tabDiscover": "ಅನ್ವೇಷಿಸಿ",
        "tabProfile": "ಪ್ರೊಫೈಲ್",
        "yourImpact": "ನಿಮ್ಮ ಪರಿಣಾಮ",
        "totalCollected": "ಒಟ್ಟು ಸಂಗ್ರಹ",
        "cleanupJobs": "ಸ್ವಚ್ಛತಾ ಕೆಲಸಗಳು",
        "signIn": "ಸೈನ್ ಇನ್",
        "welcome": "ಸ್ವಾಗತ"
    ]
}

// MARK: - Localized Text View

struct LocalizedText: View {
    let key: LocalizedKey
    var font: Font = .body
    var color: Color = .primary

    var body: some View {
        Text(LocalizationManager.shared.localized(key))
            .font(font)
            .foregroundColor(color)
    }
}

// MARK: - Language Picker View

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        LocalizationManager.shared.currentLanguage = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if LocalizationManager.shared.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Language / भाषा")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - String Extension for Localization

extension String {
    @MainActor
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}

#Preview {
    LanguagePickerView()
}
