// ViewModels.swift
// View models for the app (local mode)

import Foundation
import Combine

// MARK: - Feed View Model

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var hasMorePosts = true

    private var currentFilter: FeedView.PostFilter = .all

    init() {
        loadPosts()
    }

    func loadPosts() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let newPosts = try await PostService.shared.getPosts(
                    state: currentFilter == .myState ? UserState.shared.currentUser?.state : nil,
                    district: currentFilter == .myDistrict ? UserState.shared.currentUser?.district : nil
                )

                posts = newPosts
                hasMorePosts = newPosts.count >= 20
            } catch {
                print("Error loading posts: \(error)")
            }
            isLoading = false
        }
    }

    func loadMore() {
        // Local storage doesn't need pagination for now
    }

    func refresh() {
        posts = []
        hasMorePosts = true
        loadPosts()
    }

    func refreshAsync() async {
        posts = []
        hasMorePosts = true

        do {
            let newPosts = try await PostService.shared.getPosts()
            posts = newPosts
            hasMorePosts = newPosts.count >= 20
        } catch {
            print("Error refreshing: \(error)")
        }
    }

    func applyFilter(_ filter: FeedView.PostFilter) {
        currentFilter = filter
        refresh()
    }
}

// MARK: - Post Detail View Model

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false

    private let postId: String

    init(postId: String) {
        self.postId = postId
        loadComments()
    }

    func loadComments() {
        Task {
            isLoading = true
            do {
                comments = try await PostService.shared.getComments(postId: postId)
            } catch {
                print("Error loading comments: \(error)")
            }
            isLoading = false
        }
    }

    func addComment(_ text: String) async {
        guard let userId = AuthManager.shared.currentUserId,
              let user = UserState.shared.currentUser else { return }

        do {
            let comment = try await PostService.shared.addComment(
                postId: postId,
                userId: userId,
                userName: user.displayName,
                userPhotoURL: user.photoURL,
                text: text
            )
            comments.append(comment)
        } catch {
            print("Error adding comment: \(error)")
        }
    }
}

// MARK: - Leaderboard View Model

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false

    func loadLeaderboard(scope: LeaderboardView.LeaderboardScope) {
        isLoading = true

        Task {
            do {
                var users = try await UserService.shared.getAllUsers()

                switch scope {
                case .state:
                    if let state = UserState.shared.currentUser?.state {
                        users = users.filter { $0.state == state }
                    }
                case .district:
                    if let district = UserState.shared.currentUser?.district {
                        users = users.filter { $0.district == district }
                    }
                case .city, .global:
                    break
                }

                // Sort by points and create entries
                let sortedUsers = users.sorted { $0.totalPoints > $1.totalPoints }

                entries = sortedUsers.enumerated().map { index, user in
                    LeaderboardEntry(
                        id: user.id,
                        userId: user.id,
                        displayName: user.displayName,
                        photoURL: user.photoURL,
                        points: user.totalPoints,
                        level: user.levelName,
                        rank: index + 1,
                        totalPosts: user.totalPosts,
                        totalWasteKg: user.totalWasteKg,
                        state: user.state,
                        district: user.district,
                        city: nil,
                        pincode: nil
                    )
                }

                // If no users, add sample entries
                if entries.isEmpty {
                    entries = createSampleLeaderboard()
                }
            } catch {
                print("Error loading leaderboard: \(error)")
                entries = createSampleLeaderboard()
            }
            isLoading = false
        }
    }

    private func createSampleLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(id: "1", userId: "1", displayName: "Rajesh Kumar", photoURL: nil, points: 5420, level: "Eco Champion", rank: 1, totalPosts: 87, totalWasteKg: 432.5, state: "Maharashtra", district: "Mumbai", city: nil, pincode: nil),
            LeaderboardEntry(id: "2", userId: "2", displayName: "Priya Sharma", photoURL: nil, points: 4850, level: "Nature Defender", rank: 2, totalPosts: 72, totalWasteKg: 380.2, state: "Delhi", district: "South Delhi", city: nil, pincode: nil),
            LeaderboardEntry(id: "3", userId: "3", displayName: "Arjun Patel", photoURL: nil, points: 4200, level: "Nature Defender", rank: 3, totalPosts: 65, totalWasteKg: 325.0, state: "Gujarat", district: "Ahmedabad", city: nil, pincode: nil),
            LeaderboardEntry(id: "4", userId: "4", displayName: "Ananya Reddy", photoURL: nil, points: 3800, level: "Green Guardian", rank: 4, totalPosts: 58, totalWasteKg: 290.5, state: "Telangana", district: "Hyderabad", city: nil, pincode: nil),
            LeaderboardEntry(id: "5", userId: "5", displayName: "Vikram Singh", photoURL: nil, points: 3500, level: "Green Guardian", rank: 5, totalPosts: 52, totalWasteKg: 265.8, state: "Rajasthan", district: "Jaipur", city: nil, pincode: nil)
        ]
    }
}

// MARK: - Gatherings View Model

@MainActor
class GatheringsViewModel: ObservableObject {
    @Published var gatherings: [Gathering] = []
    @Published var isLoading = false

    private var currentFilter: GatheringsView.EventFilter = .upcoming

    init() {
        loadGatherings()
    }

    func loadGatherings() {
        isLoading = true

        Task {
            do {
                let filter: GatheringsFilter
                switch currentFilter {
                case .upcoming: filter = .upcoming
                case .past: filter = .past
                case .myEvents: filter = .myEvents
                }

                gatherings = try await GatheringService.shared.getGatherings(filter: filter)
            } catch {
                print("Error loading gatherings: \(error)")
            }
            isLoading = false
        }
    }

    func refresh() {
        loadGatherings()
    }

    func refreshAsync() async {
        isLoading = true
        do {
            gatherings = try await GatheringService.shared.getGatherings()
        } catch {
            print("Error refreshing: \(error)")
        }
        isLoading = false
    }

    func applyFilter(_ filter: GatheringsView.EventFilter) {
        currentFilter = filter
        refresh()
    }
}

// MARK: - Event Detail View Model

@MainActor
class EventDetailViewModel: ObservableObject {
    @Published var supplyRequests: [SupplyRequest] = []
    @Published var isLoading = false

    private let gatheringId: String

    init(gatheringId: String) {
        self.gatheringId = gatheringId
        loadSupplies()
    }

    func loadSupplies() {
        Task {
            do {
                supplyRequests = try await GatheringService.shared.getSupplyRequests(gatheringId: gatheringId)
            } catch {
                print("Error loading supplies: \(error)")
            }
        }
    }
}

// MARK: - Companies View Model

@MainActor
class CompaniesViewModel: ObservableObject {
    @Published var companies: [CleaningCompany] = []
    @Published var isLoading = false

    init() {
        loadCompanies()
    }

    func loadCompanies() {
        isLoading = true

        // Load sample companies for demo
        companies = [
            CleaningCompany(
                id: "1",
                name: "SparkleClean Services",
                description: "Professional cleaning services for homes and offices. Eco-friendly products and satisfaction guarantee.",
                logoURL: nil,
                coverImageURL: nil,
                categories: ["residential", "commercial", "deep_cleaning"],
                serviceAreas: ["Mumbai", "Thane", "Navi Mumbai"],
                startingPrice: 999,
                rating: 4.7,
                reviewCount: 234,
                completedJobs: 1580,
                phone: "+91 98765 43210",
                email: "info@sparkleclean.com",
                website: nil,
                operatingHours: "Mon-Sat: 8AM - 8PM",
                verified: true,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            ),
            CleaningCompany(
                id: "2",
                name: "GreenClean India",
                description: "Sustainable cleaning solutions. We use only eco-friendly, biodegradable products.",
                logoURL: nil,
                coverImageURL: nil,
                categories: ["residential", "eco_friendly"],
                serviceAreas: ["Delhi", "Gurgaon", "Noida"],
                startingPrice: 799,
                rating: 4.5,
                reviewCount: 189,
                completedJobs: 1250,
                phone: "+91 98765 12345",
                email: nil,
                website: nil,
                operatingHours: "Mon-Sun: 7AM - 9PM",
                verified: true,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            ),
            CleaningCompany(
                id: "3",
                name: "ProClean Experts",
                description: "Industrial and commercial cleaning specialists. ISO certified.",
                logoURL: nil,
                coverImageURL: nil,
                categories: ["commercial", "industrial"],
                serviceAreas: ["Bangalore", "Chennai", "Hyderabad"],
                startingPrice: 1499,
                rating: 4.8,
                reviewCount: 312,
                completedJobs: 2100,
                phone: "+91 98765 67890",
                email: nil,
                website: nil,
                operatingHours: "24/7 Available",
                verified: true,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            )
        ]

        isLoading = false
    }

    func refreshAsync() async {
        loadCompanies()
    }
}

// MARK: - Company Detail View Model

@MainActor
class CompanyDetailViewModel: ObservableObject {
    @Published var services: [CleaningService] = []
    @Published var reviews: [Review] = []
    @Published var ratingDistribution: [Int: Int] = [:]
    @Published var isLoading = false

    private let companyId: String

    init(companyId: String) {
        self.companyId = companyId
        loadData()
    }

    func loadData() {
        isLoading = true

        // Sample services
        services = [
            CleaningService(id: "1", companyId: companyId, name: "Basic Home Cleaning", description: "Complete cleaning of all rooms", price: 999, duration: "2-3 hours", includes: ["Dusting", "Mopping", "Bathroom"]),
            CleaningService(id: "2", companyId: companyId, name: "Deep Cleaning", description: "Thorough deep cleaning service", price: 2499, duration: "4-5 hours", includes: ["All basic", "Carpet cleaning", "AC vent cleaning"]),
            CleaningService(id: "3", companyId: companyId, name: "Kitchen Cleaning", description: "Complete kitchen deep clean", price: 1499, duration: "2-3 hours", includes: ["Chimney", "Cabinets", "Appliances"])
        ]

        // Sample reviews
        reviews = [
            Review(id: "1", companyId: companyId, userId: "u1", userName: "Ravi Kumar", userPhotoURL: nil, rating: 5, text: "Excellent service! Very professional team.", images: [], helpfulCount: 12, bookingId: nil, createdAt: Date().addingTimeInterval(-86400)),
            Review(id: "2", companyId: companyId, userId: "u2", userName: "Meera Patel", userPhotoURL: nil, rating: 4, text: "Good service, on time. Would recommend.", images: [], helpfulCount: 8, bookingId: nil, createdAt: Date().addingTimeInterval(-172800))
        ]

        // Rating distribution
        ratingDistribution = [5: 150, 4: 60, 3: 15, 2: 5, 1: 4]

        isLoading = false
    }
}
