// EventTasksView.swift
// Task assignment and management for event organizers

import SwiftUI

struct EventTasksView: View {
    let event: Gathering
    let isOrganizer: Bool

    @State private var tasks: [EventTask] = []
    @State private var showCreateTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var isLoading = false

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case assigned = "Assigned"
        case completed = "Completed"
    }

    var filteredTasks: [EventTask] {
        switch selectedFilter {
        case .all: return tasks
        case .open: return tasks.filter { $0.status == .open }
        case .assigned: return tasks.filter { $0.status == .assigned || $0.status == .inProgress }
        case .completed: return tasks.filter { $0.status == .completed }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterHeader

            // Task stats
            if isOrganizer {
                taskStats
            }

            // Task list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            TaskCardSkeleton()
                        }
                    } else if filteredTasks.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredTasks) { task in
                            TaskCard(
                                task: task,
                                isOrganizer: isOrganizer,
                                onVolunteer: { volunteerForTask($0) },
                                onComplete: { markTaskComplete($0) }
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOrganizer {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskSheet(eventId: event.id) { newTask in
                tasks.append(newTask)
            }
        }
        .onAppear {
            loadTasks()
        }
    }

    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        count: countFor(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    private var taskStats: some View {
        HStack(spacing: 16) {
            StatPill(value: tasks.count, label: "Total", color: .blue)
            StatPill(value: tasks.filter { $0.status == .open }.count, label: "Open", color: .orange)
            StatPill(value: tasks.filter { $0.status == .completed }.count, label: "Done", color: .green)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))

            Text(selectedFilter == .all ? "No tasks yet" : "No \(selectedFilter.rawValue.lowercased()) tasks")
                .font(.headline)

            if isOrganizer {
                Text("Create tasks to organize volunteers and track progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showCreateTask = true
                } label: {
                    Label("Create Task", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            } else {
                Text("The organizer hasn't created any tasks yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
    }

    private func countFor(_ filter: TaskFilter) -> Int {
        switch filter {
        case .all: return tasks.count
        case .open: return tasks.filter { $0.status == .open }.count
        case .assigned: return tasks.filter { $0.status == .assigned || $0.status == .inProgress }.count
        case .completed: return tasks.filter { $0.status == .completed }.count
        }
    }

    private func loadTasks() {
        isLoading = true
        Task {
            do {
                tasks = try await FirestoreService.shared.getEventTasks(eventId: event.id)
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    private func volunteerForTask(_ task: EventTask) {
        guard let currentUser = UserState.shared.currentUser else { return }
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        // Optimistically update UI
        tasks[index].currentVolunteers += 1
        if tasks[index].currentVolunteers >= tasks[index].maxVolunteers {
            tasks[index].status = .assigned
        }
        tasks[index].assigneeId = currentUser.id
        tasks[index].assigneeName = currentUser.displayName

        // Save to Firestore
        Task {
            do {
                let volunteer = TaskVolunteer(
                    id: UUID().uuidString,
                    taskId: task.id,
                    userId: currentUser.id,
                    userName: currentUser.displayName,
                    userPhotoURL: currentUser.photoURL,
                    status: .volunteered,
                    joinedAt: Date()
                )
                try await FirestoreService.shared.volunteerForTask(taskId: task.id, volunteer: volunteer)
            } catch {
                // Silently fail
            }
        }
    }

    private func markTaskComplete(_ task: EventTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        // Optimistically update UI
        tasks[index].status = .completed
        tasks[index].completedAt = Date()

        // Save to Firestore
        Task {
            do {
                try await FirestoreService.shared.updateTaskStatus(taskId: task.id, status: .completed)
            } catch {
                // Silently fail
            }
        }
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: EventTask
    let isOrganizer: Bool
    let onVolunteer: (EventTask) -> Void
    let onComplete: (EventTask) -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Category icon
                Image(systemName: task.category.icon)
                    .font(.title3)
                    .foregroundColor(categoryColor)
                    .frame(width: 36, height: 36)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(task.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if task.priority == .high || task.priority == .critical {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(task.priority.rawValue)
                            }
                            .font(.caption)
                            .foregroundColor(task.priority == .critical ? .red : .orange)
                        }
                    }
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Description
            if let description = task.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(showDetails ? nil : 2)
            }

            // Volunteer info
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                Text("\(task.currentVolunteers)/\(task.maxVolunteers) volunteers")
                    .font(.caption)

                if let assignee = task.assigneeName {
                    Text("Assigned to: \(assignee)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(.secondary)

            // Due time
            if let dueTime = task.dueTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("Due: \(dueTime.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Action buttons
            HStack(spacing: 12) {
                if task.status == .open && task.currentVolunteers < task.maxVolunteers {
                    Button {
                        onVolunteer(task)
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Volunteer")
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }

                if isOrganizer && task.status != .completed {
                    Button {
                        onComplete(task)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Mark Complete")
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                }

                Spacer()

                Button {
                    withAnimation {
                        showDetails.toggle()
                    }
                } label: {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var categoryColor: Color {
        switch task.category {
        case .setup: return .orange
        case .cleanup: return .green
        case .registration: return .blue
        case .photography: return .purple
        case .refreshments: return .brown
        case .transport: return .indigo
        case .safety: return .red
        case .coordination: return .teal
        case .other: return .gray
        }
    }

    private var statusBadge: some View {
        Text(task.status.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch task.status {
        case .open: return .blue
        case .assigned: return .orange
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

// MARK: - Create Task Sheet

struct CreateTaskSheet: View {
    let eventId: String
    let onSave: (EventTask) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: EventTask.TaskCategory = .other
    @State private var priority: EventTask.TaskPriority = .medium
    @State private var maxVolunteers = 1
    @State private var hasDueTime = false
    @State private var dueTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Category & Priority") {
                    Picker("Category", selection: $category) {
                        ForEach(EventTask.TaskCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(EventTask.TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }

                Section("Volunteers") {
                    Stepper("Needed: \(maxVolunteers)", value: $maxVolunteers, in: 1...20)
                }

                Section("Due Time") {
                    Toggle("Set due time", isOn: $hasDueTime)

                    if hasDueTime {
                        DatePicker("Due", selection: $dueTime)
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func createTask() {
        let task = EventTask(
            id: UUID().uuidString,
            eventId: eventId,
            creatorId: UserState.shared.currentUser?.id ?? "",
            title: title,
            description: description.isEmpty ? nil : description,
            category: category,
            priority: priority,
            status: .open,
            assigneeId: nil,
            assigneeName: nil,
            maxVolunteers: maxVolunteers,
            currentVolunteers: 0,
            dueTime: hasDueTime ? dueTime : nil,
            completedAt: nil,
            createdAt: Date()
        )

        onSave(task)
        dismiss()
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct StatPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TaskCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 14)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 10)
                }

                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shimmer()
    }
}

#Preview {
    NavigationStack {
        EventTasksView(event: .preview, isOrganizer: true)
    }
}
