// EventSuppliesView.swift
// Supply ordering and contribution system for events

import SwiftUI

struct EventSuppliesView: View {
    let event: Gathering
    let isOrganizer: Bool

    @State private var supplies: [SupplyItem] = []
    @State private var showAddSupply = false
    @State private var selectedCategory: SupplyCategory?
    @State private var isLoading = false

    var filteredSupplies: [SupplyItem] {
        guard let category = selectedCategory else { return supplies }
        return supplies.filter { $0.category == category.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            categoryFilter

            // Summary stats
            summaryStats

            // Supplies list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            SupplyCardSkeleton()
                        }
                    } else if filteredSupplies.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSupplies) { supply in
                            SupplyCard(
                                supply: supply,
                                isOrganizer: isOrganizer,
                                onContribute: { showContributeSheet(for: $0) }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Supplies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOrganizer {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddSupply = true
                        } label: {
                            Label("Add Custom Item", systemImage: "plus")
                        }

                        Menu("Add from Template") {
                            ForEach(SupplyTemplate.all, id: \.category) { template in
                                Button(template.category) {
                                    addFromTemplate(template)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSupply) {
            AddSupplySheet(eventId: event.id) { newSupply in
                supplies.append(newSupply)
            }
        }
        .onAppear {
            loadSupplies()
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    icon: "tray.full.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(SupplyCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: iconFor(category),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    private var summaryStats: some View {
        HStack(spacing: 12) {
            SummaryCard(
                icon: "shippingbox.fill",
                value: "\(supplies.count)",
                label: "Items Needed",
                color: .blue
            )

            SummaryCard(
                icon: "checkmark.circle.fill",
                value: "\(supplies.filter { $0.isFulfilled }.count)",
                label: "Fulfilled",
                color: .green
            )

            SummaryCard(
                icon: "person.3.fill",
                value: "\(totalContributors)",
                label: "Contributors",
                color: .purple
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text("No supplies requested")
                .font(.headline)

            if isOrganizer {
                Text("Add supplies that volunteers can contribute to the event")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showAddSupply = true
                } label: {
                    Label("Add Supply", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            } else {
                Text("The organizer hasn't requested any supplies yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
    }

    private var totalContributors: Int {
        // Count unique contributors
        10 // Mock value
    }

    private func iconFor(_ category: SupplyCategory) -> String {
        switch category {
        case .cleanupKit: return "trash.fill"
        case .safetyGear: return "cross.case.fill"
        case .foodRefreshments: return "cup.and.saucer.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .custom: return "ellipsis.circle.fill"
        }
    }

    private func loadSupplies() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            supplies = [
                SupplyItem.preview,
                SupplyItem(
                    id: "supply-2",
                    eventId: event.id,
                    requesterId: "user-1",
                    category: "Safety Gear",
                    name: "Disposable Gloves",
                    description: "Latex or nitrile gloves for handling waste",
                    quantity: 200,
                    unit: "pairs",
                    estimatedCost: 800,
                    fulfilledQuantity: 200,
                    deliveryAddress: nil,
                    deliveryInstructions: nil,
                    status: .fulfilled,
                    urgency: .medium,
                    createdAt: Date(),
                    neededBy: nil
                ),
                SupplyItem(
                    id: "supply-3",
                    eventId: event.id,
                    requesterId: "user-1",
                    category: "Food & Refreshments",
                    name: "Bottled Water (500ml)",
                    description: "For volunteer hydration",
                    quantity: 100,
                    unit: "bottles",
                    estimatedCost: 1500,
                    fulfilledQuantity: 30,
                    deliveryAddress: "Juhu Beach, Near Lifeguard Station",
                    deliveryInstructions: "Deliver by 6:30 AM",
                    status: .partiallyFulfilled,
                    urgency: .urgent,
                    createdAt: Date(),
                    neededBy: Date().addingTimeInterval(86400)
                )
            ]
            isLoading = false
        }
    }

    private func addFromTemplate(_ template: SupplyTemplate) {
        for item in template.items {
            let supply = SupplyItem(
                id: UUID().uuidString,
                eventId: event.id,
                requesterId: UserState.shared.currentUser?.id ?? "",
                category: template.category,
                name: item.name,
                description: nil,
                quantity: item.defaultQty,
                unit: item.unit,
                estimatedCost: nil,
                fulfilledQuantity: 0,
                deliveryAddress: nil,
                deliveryInstructions: nil,
                status: .requested,
                urgency: .medium,
                createdAt: Date(),
                neededBy: event.eventDate
            )
            supplies.append(supply)
        }
    }

    private func showContributeSheet(for supply: SupplyItem) {
        // TODO: Show contribution sheet
    }
}

// MARK: - Supply Card

struct SupplyCard: View {
    let supply: SupplyItem
    let isOrganizer: Bool
    let onContribute: (SupplyItem) -> Void

    @State private var showContribute = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(supply.name)
                            .font(.subheadline.weight(.semibold))

                        if supply.urgency == .urgent {
                            Text("URGENT")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }

                    Text(supply.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status
                statusBadge
            }

            // Description
            if let description = supply.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: supply.fulfillmentPercentage)
                    .tint(progressColor)

                HStack {
                    Text("\(supply.fulfilledQuantity)/\(supply.quantity) \(supply.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(supply.fulfillmentPercentage * 100))%")
                        .font(.caption.weight(.medium))
                        .foregroundColor(progressColor)
                }
            }

            // Delivery info
            if let address = supply.deliveryAddress {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text(address)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            if let neededBy = supply.neededBy {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                    Text("Needed by: \(neededBy.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption)
                .foregroundColor(neededBy < Date() ? .red : .secondary)
            }

            // Estimated cost
            if let cost = supply.estimatedCost {
                HStack(spacing: 4) {
                    Image(systemName: "indianrupeesign.circle.fill")
                    Text("Est. cost: \(cost)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Action button
            if !supply.isFulfilled {
                Button {
                    showContribute = true
                } label: {
                    HStack {
                        Image(systemName: "gift.fill")
                        Text("Contribute")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showContribute) {
            ContributeSupplySheet(supply: supply)
        }
    }

    private var statusBadge: some View {
        Text(supply.status.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch supply.status {
        case .requested: return .blue
        case .partiallyFulfilled: return .orange
        case .fulfilled: return .green
        case .delivered: return .green
        case .cancelled: return .gray
        }
    }

    private var progressColor: Color {
        if supply.fulfillmentPercentage >= 1.0 { return .green }
        if supply.fulfillmentPercentage >= 0.5 { return .orange }
        return .blue
    }
}

// MARK: - Contribute Supply Sheet

struct ContributeSupplySheet: View {
    let supply: SupplyItem
    @Environment(\.dismiss) private var dismiss

    @State private var quantity = 1
    @State private var isMonetary = false
    @State private var deliveryMethod: SupplyContribution.DeliveryMethod = .dropOff
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var safetyAcknowledged = false

    private var remainingNeeded: Int {
        max(supply.quantity - supply.fulfilledQuantity, 1)
    }

    private var requiresSafetyAck: Bool {
        deliveryMethod == .shipping && supply.deliveryAddress != nil
    }

    private var canSubmit: Bool {
        !requiresSafetyAck || safetyAcknowledged
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(supply.name)
                            .font(.headline)
                        Text("Needed: \(remainingNeeded) \(supply.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Your Contribution") {
                    Toggle("I'll pay for it instead", isOn: $isMonetary)

                    if isMonetary {
                        if let cost = supply.estimatedCost {
                            let perUnit = cost / max(supply.quantity, 1)
                            Text("Estimated cost: ₹\(perUnit * quantity)")
                                .foregroundColor(.green)
                        }
                    }

                    Stepper("Quantity: \(quantity) \(supply.unit)", value: $quantity, in: 1...remainingNeeded)
                }

                Section {
                    Picker("How will you deliver?", selection: $deliveryMethod) {
                        ForEach([SupplyContribution.DeliveryMethod.dropOff, .shipping, .handover, .purchase], id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }

                    if deliveryMethod == .shipping, let address = supply.deliveryAddress {
                        // Safety Warning
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.orange)
                                Text("Safety Notice")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.orange)
                            }

                            Text("Verify the event organizer's identity before shipping supplies. CleanConnect is not responsible for delivery disputes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delivery Address:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(address)
                                .font(.subheadline)
                        }

                        Toggle(isOn: $safetyAcknowledged) {
                            Text("I understand the delivery risks")
                                .font(.caption)
                        }
                        .tint(.green)
                    }
                } header: {
                    Text("Delivery")
                } footer: {
                    if deliveryMethod == .shipping {
                        Text("Always verify recipient details before shipping valuable items.")
                            .font(.caption2)
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Any special notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Contribute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pledge") {
                        submitContribution()
                    }
                    .disabled(isSubmitting || !canSubmit)
                }
            }
        }
    }

    private func submitContribution() {
        isSubmitting = true
        // TODO: Save contribution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Add Supply Sheet

struct AddSupplySheet: View {
    let eventId: String
    let onSave: (SupplyItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var category: SupplyCategory = .custom
    @State private var quantity = 10
    @State private var unit = "pieces"
    @State private var estimatedCost = ""
    @State private var urgency: SupplyItem.SupplyUrgency = .medium
    @State private var deliveryAddress = ""
    @State private var deliveryInstructions = ""
    @State private var hasDeadline = false
    @State private var neededBy = Date()

    let units = ["pieces", "pairs", "kg", "liters", "boxes", "sets", "bottles", "packets"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Category", selection: $category) {
                        ForEach(SupplyCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Quantity") {
                    Stepper("Amount: \(quantity)", value: $quantity, in: 1...1000)

                    Picker("Unit", selection: $unit) {
                        ForEach(units, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }

                    TextField("Estimated total cost (optional)", text: $estimatedCost)
                        .keyboardType(.numberPad)
                }

                Section("Urgency") {
                    Picker("How urgent?", selection: $urgency) {
                        ForEach([SupplyItem.SupplyUrgency.low, .medium, .urgent], id: \.self) { u in
                            Text(u.rawValue).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Set deadline", isOn: $hasDeadline)

                    if hasDeadline {
                        DatePicker("Needed by", selection: $neededBy)
                    }
                }

                Section {
                    // Safety Warning for address sharing
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                            Text("Safety First")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.orange)
                        }

                        Text("Only share delivery addresses with verified event participants. Consider using a public meeting point instead of personal addresses.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    TextField("Delivery address", text: $deliveryAddress)

                    TextField("Special instructions", text: $deliveryInstructions, axis: .vertical)
                        .lineLimit(2...3)
                } header: {
                    Text("Delivery (Optional)")
                } footer: {
                    Text("Tip: Use event venue or nearby public location as the delivery point.")
                        .font(.caption2)
                }
            }
            .navigationTitle("Request Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveSupply()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveSupply() {
        let supply = SupplyItem(
            id: UUID().uuidString,
            eventId: eventId,
            requesterId: UserState.shared.currentUser?.id ?? "",
            category: category.rawValue,
            name: name,
            description: description.isEmpty ? nil : description,
            quantity: quantity,
            unit: unit,
            estimatedCost: Int(estimatedCost),
            fulfilledQuantity: 0,
            deliveryAddress: deliveryAddress.isEmpty ? nil : deliveryAddress,
            deliveryInstructions: deliveryInstructions.isEmpty ? nil : deliveryInstructions,
            status: .requested,
            urgency: urgency,
            createdAt: Date(),
            neededBy: hasDeadline ? neededBy : nil
        )

        onSave(supply)
        dismiss()
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SupplyCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                }
                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 8)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 40)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shimmer()
    }
}

#Preview {
    NavigationStack {
        EventSuppliesView(event: .preview, isOrganizer: true)
    }
}
