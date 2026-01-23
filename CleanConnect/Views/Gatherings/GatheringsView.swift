// GatheringsView.swift
// Community events and cleanup drives

import SwiftUI

struct GatheringsView: View {
    @StateObject private var viewModel = GatheringsViewModel()
    @State private var showCreateEvent = false
    @State private var selectedFilter: EventFilter = .upcoming

    enum EventFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case myEvents = "My Events"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedFilter) { _, newFilter in
                    viewModel.applyFilter(newFilter)
                }

                if viewModel.isLoading && viewModel.gatherings.isEmpty {
                    Spacer()
                    ProgressView("Loading events...")
                    Spacer()
                } else if viewModel.gatherings.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }
            .navigationTitle("Community Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateEvent = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(onEventCreated: {
                    viewModel.refresh()
                })
            }
            .refreshable {
                await viewModel.refreshAsync()
            }
        }
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.gatherings) { gathering in
                    NavigationLink(destination: EventDetailView(gathering: gathering)) {
                        EventCard(gathering: gathering)
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
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.5))
            Text("No events found")
                .font(.headline)
            Text("Be the first to organize a cleanup drive!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Create Event") {
                showCreateEvent = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            Spacer()
        }
        .padding()
    }
}

struct EventCard: View {
    let gathering: Gathering

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header image
            if let imageURL = gathering.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green.opacity(0.5))
                        )
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
            }

            // Event info
            VStack(alignment: .leading, spacing: 8) {
                Text(gathering.title)
                    .font(.headline)
                    .lineLimit(2)

                // Date and time
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                    Text(gathering.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }

                // Location
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text("\(gathering.district), \(gathering.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Stats row
                HStack(spacing: 16) {
                    Label("\(gathering.attendeesCount)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let goal = gathering.fundraisingGoal, goal > 0 {
                        Label("₹\(gathering.fundraisingRaised ?? 0)/₹\(goal)", systemImage: "indianrupeesign.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    // Status badge
                    Text(gathering.status.capitalized)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(gathering.status).opacity(0.2))
                        .foregroundColor(statusColor(gathering.status))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "upcoming": return .blue
        case "ongoing": return .green
        case "completed": return .gray
        case "cancelled": return .red
        default: return .gray
        }
    }
}

#Preview {
    GatheringsView()
}
