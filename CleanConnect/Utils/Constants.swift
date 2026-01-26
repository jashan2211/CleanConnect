// Constants.swift
// App constants and configuration

import Foundation

// MARK: - Indian States and Districts

struct IndianStates {
    static let all: [String] = [
        "Andhra Pradesh",
        "Arunachal Pradesh",
        "Assam",
        "Bihar",
        "Chhattisgarh",
        "Delhi",
        "Goa",
        "Gujarat",
        "Haryana",
        "Himachal Pradesh",
        "Jharkhand",
        "Karnataka",
        "Kerala",
        "Madhya Pradesh",
        "Maharashtra",
        "Manipur",
        "Meghalaya",
        "Mizoram",
        "Nagaland",
        "Odisha",
        "Punjab",
        "Rajasthan",
        "Sikkim",
        "Tamil Nadu",
        "Telangana",
        "Tripura",
        "Uttar Pradesh",
        "Uttarakhand",
        "West Bengal"
    ]

    static func districts(for state: String) -> [String] {
        switch state {
        case "Maharashtra":
            return ["Mumbai", "Pune", "Nagpur", "Thane", "Nashik", "Aurangabad", "Solapur", "Kolhapur", "Sangli", "Satara", "Ratnagiri", "Sindhudurg", "Ahmednagar"]
        case "Delhi":
            return ["Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North East Delhi", "North West Delhi", "Shahdara", "South Delhi", "South East Delhi", "South West Delhi", "West Delhi"]
        case "Karnataka":
            return ["Bangalore Urban", "Bangalore Rural", "Mysore", "Mangalore", "Hubli-Dharwad", "Belgaum", "Gulbarga", "Bellary", "Shimoga", "Tumkur"]
        case "Tamil Nadu":
            return ["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Tirupur", "Vellore", "Erode", "Thoothukkudi"]
        case "Gujarat":
            return ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Junagadh", "Gandhinagar", "Anand", "Kheda"]
        case "Rajasthan":
            return ["Jaipur", "Jodhpur", "Udaipur", "Kota", "Bikaner", "Ajmer", "Alwar", "Bharatpur", "Sikar", "Pali"]
        case "Uttar Pradesh":
            return ["Lucknow", "Kanpur", "Agra", "Varanasi", "Allahabad", "Meerut", "Ghaziabad", "Noida", "Bareilly", "Aligarh", "Moradabad", "Gorakhpur"]
        case "West Bengal":
            return ["Kolkata", "Howrah", "Durgapur", "Asansol", "Siliguri", "Bardhaman", "Malda", "Kharagpur", "Haldia", "Darjeeling"]
        case "Kerala":
            return ["Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam", "Kannur", "Alappuzha", "Palakkad", "Malappuram", "Kottayam"]
        case "Telangana":
            return ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar", "Khammam", "Ramagundam", "Mahbubnagar", "Nalgonda", "Adilabad", "Suryapet"]
        case "Bihar":
            return ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur", "Darbhanga", "Purnia", "Bihar Sharif", "Arrah", "Begusarai", "Katihar"]
        case "Punjab":
            return ["Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Bathinda", "Mohali", "Pathankot", "Hoshiarpur", "Batala", "Moga"]
        default:
            return ["District 1", "District 2", "District 3", "District 4", "District 5"]
        }
    }
}

// MARK: - App Configuration

struct AppConfig {
    static let appName = "CleanConnect"
    static let appVersion = "1.0.0"

    // Firebase collections
    struct Collections {
        static let users = "users"
        static let posts = "posts"
        static let gatherings = "gatherings"
        static let cleaningCompanies = "cleaningCompanies"
        static let bookings = "bookings"
        static let reviews = "reviews"
        static let wallets = "wallets"
        static let campaigns = "campaigns"
        static let squads = "squads"
    }

    // Payment configuration
    struct Payment {
        static let platformFeePercent = 0.07 // 7%
        static let creatorSharePercent = 0.93 // 93%
        static let gstPercent = 0.18 // 18% GST
        static let upiLimit = 100000 // ₹1,00,000 UPI limit
        static let minTipAmount = 10 // ₹10
        static let maxTipAmount = 10000 // ₹10,000
    }

    // Gamification
    struct Points {
        static let postCreated = 50
        static let eventOrganized = 100
        static let eventAttended = 25
        static let tipReceivedPer10 = 1
    }

    // Limits
    struct Limits {
        static let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
        static let maxDescriptionLength = 500
        static let maxBioLength = 150
        static let postsPerPage = 20
    }

    // URLs
    struct URLs {
        static let termsOfService = "https://thebighead.ca/CleanConnect/terms"
        static let privacyPolicy = "https://thebighead.ca/CleanConnect/privacy"
        static let helpCenter = "https://thebighead.ca/CleanConnect/support"
        static let contactEmail = "support@thebighead.ca"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let postCreated = Notification.Name("postCreated")
    static let levelUp = Notification.Name("levelUp")
    static let badgeEarned = Notification.Name("badgeEarned")
}
