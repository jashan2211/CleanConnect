// GatheringsViewModel.swift
// View model for gatherings/events view

import Foundation
import Combine

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
