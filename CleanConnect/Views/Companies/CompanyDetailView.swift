// CompanyDetailView.swift
// Detailed view of a cleaning company

import SwiftUI

struct CompanyDetailView: View {
    let company: CleaningCompany
    @StateObject private var viewModel: CompanyDetailViewModel
    @State private var selectedTab: DetailTab = .services
    @State private var showBookingSheet = false
    @State private var showEnquirySheet = false

    enum DetailTab: String, CaseIterable {
        case services = "Services"
        case reviews = "Reviews"
        case about = "About"
    }

    init(company: CleaningCompany) {
        self.company = company
        _viewModel = StateObject(wrappedValue: CompanyDetailViewModel(companyId: company.id))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Tab picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab content
                switch selectedTab {
                case .services:
                    servicesSection
                case .reviews:
                    reviewsSection
                case .about:
                    aboutSection
                }
            }
        }
        .navigationTitle(company.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(action: { showEnquirySheet = true }) {
                        Label("Ask a Question", systemImage: "questionmark.circle")
                    }
                    Button(action: {}) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bookingBar
        }
        .sheet(isPresented: $showBookingSheet) {
            BookingSheet(company: company)
        }
        .sheet(isPresented: $showEnquirySheet) {
            EnquirySheet(company: company)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo and basic info
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: company.logoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Text(String(company.name.prefix(1)))
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.green)
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(company.name)
                            .font(.title2.weight(.bold))
                        if company.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(company.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f", company.rating))
                            .font(.subheadline.weight(.medium))
                        Text("(\(company.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Completed jobs
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(company.completedJobs) jobs completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Quick stats
            HStack(spacing: 0) {
                QuickStat(icon: "clock.fill", value: "2-3 hrs", label: "Avg. Time")
                Divider().frame(height: 40)
                QuickStat(icon: "indianrupeesign.circle.fill", value: "₹\(company.startingPrice)+", label: "Starting")
                Divider().frame(height: 40)
                QuickStat(icon: "calendar", value: "Available", label: "Today")
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.services) { service in
                ServiceCard(service: service) {
                    showBookingSheet = true
                }
            }
        }
        .padding()
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rating summary
            HStack(spacing: 24) {
                VStack {
                    Text(String(format: "%.1f", company.rating))
                        .font(.system(size: 48, weight: .bold))
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(company.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("\(company.reviewCount) reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    RatingBar(stars: 5, count: viewModel.ratingDistribution[5] ?? 0, total: company.reviewCount)
                    RatingBar(stars: 4, count: viewModel.ratingDistribution[4] ?? 0, total: company.reviewCount)
                    RatingBar(stars: 3, count: viewModel.ratingDistribution[3] ?? 0, total: company.reviewCount)
                    RatingBar(stars: 2, count: viewModel.ratingDistribution[2] ?? 0, total: company.reviewCount)
                    RatingBar(stars: 1, count: viewModel.ratingDistribution[1] ?? 0, total: company.reviewCount)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            // Reviews list
            ForEach(viewModel.reviews) { review in
                ReviewCard(review: review)
            }
        }
        .padding()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.headline)
                Text(company.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Service areas
            VStack(alignment: .leading, spacing: 8) {
                Text("Service Areas")
                    .font(.headline)
                FlowLayout(spacing: 8) {
                    ForEach(company.serviceAreas, id: \.self) { area in
                        Text(area)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }
            }

            // Contact
            VStack(alignment: .leading, spacing: 12) {
                Text("Contact")
                    .font(.headline)

                if let phone = company.phone {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text(phone)
                        Spacer()
                        Button("Call") {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                if let email = company.email {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text(email)
                        Spacer()
                    }
                }

                if let website = company.website {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.purple)
                        Text(website)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }

            // Operating hours
            if let hours = company.operatingHours {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Operating Hours")
                        .font(.headline)
                    Text(hours)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private var bookingBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Starting from")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("₹\(company.startingPrice)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.green)
            }

            Spacer()

            Button(action: { showBookingSheet = true }) {
                Text("Book Now")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ServiceCard: View {
    let service: CleaningService
    let onBook: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.headline)
                    Text(service.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("₹\(service.price)")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text(service.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: onBook) {
                Text("Select")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct RatingBar: View {
    let stars: Int
    let count: Int
    let total: Int

    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(stars)")
                .font(.caption)
                .frame(width: 10)
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: URL(string: review.userPhotoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.subheadline.weight(.semibold))
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        Text(review.createdAt.timeAgo())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Text(review.text)
                .font(.subheadline)

            if !review.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(review.images, id: \.self) { imageURL in
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle().fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                        }
                    }
                }
            }

            HStack {
                Button(action: {}) {
                    Label("\(review.helpfulCount)", systemImage: "hand.thumbsup")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

#Preview {
    NavigationStack {
        CompanyDetailView(company: CleaningCompany.preview)
    }
}
