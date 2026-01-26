// BookingSheet.swift
// Service booking flow with safety disclaimers and payment options

import SwiftUI

struct BookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    let company: CleaningCompany
    @State private var selectedDate = Date().addingTimeInterval(86400)
    @State private var selectedTime = "10:00 AM"
    @State private var address = ""
    @State private var notes = ""
    @State private var selectedServiceName: String?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var safetyAcknowledged = false
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    let availableTimes = ["9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"]

    // Available services with pricing
    private var availableServices: [(name: String, duration: String, price: Int)] {
        [
            ("Basic Cleaning", "2-3 hours", company.startingPrice),
            ("Deep Cleaning", "4-5 hours", company.startingPrice + 500),
            ("Move-in/Move-out", "5-6 hours", company.startingPrice + 1000)
        ]
    }

    private var selectedServicePrice: Int {
        availableServices.first { $0.name == selectedServiceName }?.price ?? company.startingPrice
    }

    private var totalPrice: Int {
        Int(Double(selectedServicePrice) * 1.18)
    }

    private var canSubmit: Bool {
        !address.isEmpty && selectedServiceName != nil && selectedPaymentMethod != nil && safetyAcknowledged
    }

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
                            HStack {
                                Text(company.name)
                                    .font(.headline)
                                if company.verified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", company.rating))
                                    .font(.caption)
                                Text("(\(company.reviewCount) reviews)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Service selection
                Section("Select Service") {
                    ForEach(availableServices, id: \.name) { service in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(service.name)
                                    .font(.subheadline)
                                Text(service.duration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("₹\(service.price)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.green)

                            if selectedServiceName == service.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedServiceName = service.name
                            }
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

                // SAFETY WARNING - Address Section
                Section {
                    // Safety Warning Banner
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                            Text("Safety First")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.orange)
                        }

                        Text("Only share your address after confirming the service provider's identity and credentials. CleanConnect is not responsible for any incidents.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    TextField("Full address", text: $address, axis: .vertical)
                        .lineLimit(2...4)

                    Toggle(isOn: $safetyAcknowledged) {
                        Text("I understand and accept the safety guidelines")
                            .font(.caption)
                    }
                    .tint(.green)
                } header: {
                    Text("Service Address")
                } footer: {
                    Text("Verify the service provider before allowing access to your premises.")
                        .font(.caption2)
                }

                // Notes
                Section("Additional Notes (Optional)") {
                    TextField("Any special instructions...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Payment Method Selection
                Section {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        HStack(spacing: 12) {
                            Image(systemName: method.icon)
                                .font(.title3)
                                .foregroundColor(method.color)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(method.displayName)
                                    .font(.subheadline)
                                Text(method.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedPaymentMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPaymentMethod = method
                            }
                        }
                    }
                } header: {
                    Text("Payment Method")
                } footer: {
                    Text("Payment will be collected after service completion. You can pay the service provider directly.")
                }

                // Price summary
                Section("Price Summary") {
                    HStack {
                        Text("Service Charge")
                        Spacer()
                        Text("₹\(selectedServicePrice)")
                    }
                    HStack {
                        Text("GST (18%)")
                        Spacer()
                        Text("₹\(Int(Double(selectedServicePrice) * 0.18))")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text("₹\(totalPrice)")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    if let method = selectedPaymentMethod {
                        HStack {
                            Text("Pay via")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: method.icon)
                                    .foregroundColor(method.color)
                                Text(method.displayName)
                            }
                            .font(.subheadline)
                        }
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
                VStack(spacing: 8) {
                    if !safetyAcknowledged && !address.isEmpty {
                        Text("Please acknowledge the safety guidelines to proceed")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Button(action: submitBooking) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Confirm Booking - ₹\(totalPrice)")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .alert("Booking Confirmed!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your booking with \(company.name) has been confirmed for ₹\(totalPrice). Pay via \(selectedPaymentMethod?.displayName ?? "selected method") after service completion.")
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
        guard selectedServiceName != nil else { return }
        guard selectedPaymentMethod != nil else { return }
        guard safetyAcknowledged else { return }

        isSubmitting = true

        Task {
            do {
                _ = try await BookingService.shared.createBooking(
                    companyId: company.id,
                    companyName: company.name,
                    serviceId: nil,
                    serviceName: selectedServiceName,
                    scheduledDate: selectedDate,
                    scheduledTime: selectedTime,
                    address: address,
                    serviceCharge: selectedServicePrice,
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

// MARK: - Payment Methods (India-focused)

enum PaymentMethod: String, CaseIterable {
    case upi = "upi"
    case googlePay = "gpay"
    case phonePe = "phonepe"
    case paytm = "paytm"
    case cash = "cash"
    case paypal = "paypal"
    case card = "card"

    var displayName: String {
        switch self {
        case .upi: return "UPI"
        case .googlePay: return "Google Pay"
        case .phonePe: return "PhonePe"
        case .paytm: return "Paytm"
        case .cash: return "Cash"
        case .paypal: return "PayPal"
        case .card: return "Credit/Debit Card"
        }
    }

    var description: String {
        switch self {
        case .upi: return "Pay using any UPI app"
        case .googlePay: return "Fast & secure payments"
        case .phonePe: return "India's payment app"
        case .paytm: return "Wallet or UPI"
        case .cash: return "Pay in cash after service"
        case .paypal: return "International payments"
        case .card: return "Visa, Mastercard, RuPay"
        }
    }

    var icon: String {
        switch self {
        case .upi: return "indianrupeesign.circle.fill"
        case .googlePay: return "g.circle.fill"
        case .phonePe: return "p.circle.fill"
        case .paytm: return "p.square.fill"
        case .cash: return "banknote.fill"
        case .paypal: return "p.circle"
        case .card: return "creditcard.fill"
        }
    }

    var color: Color {
        switch self {
        case .upi: return .green
        case .googlePay: return .blue
        case .phonePe: return .purple
        case .paytm: return .blue
        case .cash: return .green
        case .paypal: return .blue
        case .card: return .orange
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
