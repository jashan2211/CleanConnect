// CompaniesView.swift
// Cleaning services marketplace

import SwiftUI

struct CompaniesView: View {
    @StateObject private var viewModel = CompaniesViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: ServiceCategory?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search cleaning services...", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()

                // Category filters
                categoryFilters
                    .padding(.horizontal)

                // Companies list
                if viewModel.isLoading && viewModel.companies.isEmpty {
                    Spacer()
                    ProgressView("Loading services...")
                    Spacer()
                } else if filteredCompanies.isEmpty {
                    emptyState
                } else {
                    companiesList
                }
            }
            .navigationTitle("Cleaning Services")
            .refreshable {
                await viewModel.refreshAsync()
            }
        }
    }

    private var filteredCompanies: [CleaningCompany] {
        var result = viewModel.companies

        if let category = selectedCategory {
            result = result.filter { $0.categories.contains(category.rawValue) }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(ServiceCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    private var companiesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredCompanies) { company in
                    NavigationLink(destination: CompanyDetailView(company: company)) {
                        CompanyCard(company: company)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No services found")
                .font(.headline)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

enum ServiceCategory: String, CaseIterable {
    case residential = "residential"
    case commercial = "commercial"
    case neighborhood = "neighborhood"
    case deepCleaning = "deep_cleaning"
    case industrial = "industrial"
    case wasteManagement = "waste_management"

    var displayName: String {
        switch self {
        case .residential: return "Residential"
        case .commercial: return "Commercial"
        case .neighborhood: return "Neighborhood"
        case .deepCleaning: return "Deep Clean"
        case .industrial: return "Industrial"
        case .wasteManagement: return "Waste Mgmt"
        }
    }

    var icon: String {
        switch self {
        case .residential: return "house.fill"
        case .commercial: return "building.fill"
        case .neighborhood: return "building.2.fill"
        case .deepCleaning: return "sparkles"
        case .industrial: return "gearshape.2.fill"
        case .wasteManagement: return "trash.fill"
        }
    }
}

struct CompanyCard: View {
    let company: CleaningCompany
    @State private var showBookingSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Company logo
                AsyncImage(url: URL(string: company.logoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Text(String(company.name.prefix(1)))
                                .font(.title.weight(.bold))
                                .foregroundColor(.green)
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(company.name)
                            .font(.headline)
                        if company.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", company.rating))
                            .font(.caption.weight(.medium))
                        Text("(\(company.reviewCount) reviews)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(company.serviceAreas.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Categories
            HStack(spacing: 6) {
                ForEach(company.categories.prefix(3), id: \.self) { category in
                    Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }

            // Price range
            HStack {
                Text("Starting from")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("₹\(company.startingPrice)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.green)

                Spacer()

                Button {
                    showBookingSheet = true
                } label: {
                    Text("Book Now")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showBookingSheet) {
            BookingSheet(company: company)
        }
    }
}

#Preview {
    CompaniesView()
}
