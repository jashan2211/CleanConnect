// CompanyDetailViewModel.swift
// View model for company detail view

import Foundation
import Combine

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
