// EventDetailViewModel.swift
// View model for event detail view

import Foundation
import Combine

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
                // Silently fail
            }
        }
    }
}
