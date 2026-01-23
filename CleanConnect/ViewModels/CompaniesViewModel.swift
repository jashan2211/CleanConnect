// CompaniesViewModel.swift
// View model for cleaning companies list

import Foundation
import Combine

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
