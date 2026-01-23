// BookingSheet.swift
// Service booking flow

import SwiftUI

struct BookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let company: CleaningCompany
    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var selectedTime = "10:00 AM"
    @State private var address = ""
    @State private var notes = ""
    @State private var selectedService: CleaningService?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    let availableTimes = ["9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"]

    var body: some View {
        NavigationStack {
            Form {
                // Company info
                Section {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: company.logoURL ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.green.opacity(0.2))
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)

                        VStack(alignment: .leading) {
                            Text(company.name)
                                .font(.headline)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", company.rating))
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Service selection
                Section("Select Service") {
                    // Placeholder services
                    ForEach(["Basic Cleaning", "Deep Cleaning", "Move-in/Move-out"], id: \.self) { service in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(service)
                                    .font(.subheadline)
                                Text("2-3 hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("₹\(company.startingPrice + (service == "Deep Cleaning" ? 500 : 0))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.green)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Select service
                        }
                    }
                }

                // Date & Time
                Section("Schedule") {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)

                    Picker("Time", selection: $selectedTime) {
                        ForEach(availableTimes, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                }

                // Address
                Section("Service Address") {
                    TextField("Full address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Notes
                Section("Additional Notes (Optional)") {
                    TextField("Any special instructions...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Price summary
                Section("Price Summary") {
                    HStack {
                        Text("Service Charge")
                        Spacer()
                        Text("₹\(company.startingPrice)")
                    }
                    HStack {
                        Text("GST (18%)")
                        Spacer()
                        Text("₹\(Int(Double(company.startingPrice) * 0.18))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text("₹\(Int(Double(company.startingPrice) * 1.18))")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Book Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: submitBooking) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Confirm Booking")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(address.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .disabled(address.isEmpty || isSubmitting)
                .padding()
                .background(.ultraThinMaterial)
            }
            .alert("Booking Confirmed!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your booking with \(company.name) has been confirmed. You will receive a confirmation shortly.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func submitBooking() {
        guard !address.isEmpty else { return }

        isSubmitting = true

        Task {
            do {
                _ = try await BookingService.shared.createBooking(
                    companyId: company.id,
                    companyName: company.name,
                    serviceId: selectedService?.id,
                    serviceName: selectedService?.name,
                    scheduledDate: selectedDate,
                    scheduledTime: selectedTime,
                    address: address,
                    serviceCharge: selectedService?.price ?? company.startingPrice,
                    notes: notes.isEmpty ? nil : notes
                )
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct EnquirySheet: View {
    @Environment(\.dismiss) private var dismiss
    let company: CleaningCompany
    @State private var question = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ask \(company.name) a question")
                    .font(.headline)

                TextField("Type your question...", text: $question, axis: .vertical)
                    .lineLimit(4...8)
                    .textFieldStyle(.roundedBorder)

                Text("The company will respond to your enquiry via the app.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: submitEnquiry) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Enquiry")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(question.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .disabled(question.isEmpty || isSubmitting)
            }
            .padding()
            .navigationTitle("Ask a Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func submitEnquiry() {
        isSubmitting = true
        // Submit enquiry logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

#Preview {
    BookingSheet(company: CleaningCompany.preview)
}
