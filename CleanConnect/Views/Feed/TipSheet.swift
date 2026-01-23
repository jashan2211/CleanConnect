// TipSheet.swift
// Sheet for tipping content creators

import SwiftUI

struct TipSheet: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    @State private var selectedAmount: Int?
    @State private var customAmount = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    let presetAmounts = [10, 50, 100, 500, 1000]

    var tipAmount: Int? {
        if let selected = selectedAmount {
            return selected
        }
        return Int(customAmount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Disclaimer Warning
                    aiDisclaimerBanner

                    // Recipient info
                    recipientHeader

                    // Verification status
                    verificationStatusView

                    Divider()

                    // Amount selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Amount")
                            .font(.headline)

                        // Preset amounts
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(presetAmounts, id: \.self) { amount in
                                AmountButton(
                                    amount: amount,
                                    isSelected: selectedAmount == amount
                                ) {
                                    selectedAmount = amount
                                    customAmount = ""
                                }
                            }
                        }

                        // Custom amount
                        HStack {
                            Text("Custom")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("₹")
                                    .foregroundColor(.secondary)
                                TextField("Amount", text: $customAmount)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: customAmount) { _, _ in
                                        selectedAmount = nil
                                    }
                            }
                        }
                    }

                    // Payment breakdown
                    if let amount = tipAmount, amount > 0 {
                        paymentBreakdown(amount: amount)
                    }

                    Spacer()

                    // Platform fee note
                    VStack(spacing: 4) {
                        Text("5% platform fee applies")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Payment via UPI, Cards, Net Banking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Pay button
                    Button(action: processTip) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "indianrupeesign.circle.fill")
                                Text(tipAmount.map { "Pay ₹\($0)" } ?? "Select Amount")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tipAmount != nil ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .disabled(tipAmount == nil || isProcessing)
                }
            }
            .padding()
            .navigationTitle("Send Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your tip of ₹\(tipAmount ?? 0) has been sent to \(post.userName)!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var aiDisclaimerBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.ccAIWarning)
                Text("Important Disclaimer")
                    .font(.subheadline.bold())
                    .foregroundColor(.ccAIWarning)
            }

            Text("Photos and videos may be AI-generated or manipulated. We recommend tipping only verified posts with video proof. CleanConnect is not responsible for fraudulent content.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.ccAIWarning.opacity(0.1))
        .cornerRadius(12)
    }

    private var verificationStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: post.verificationBadge.icon)
                    .foregroundColor(badgeColor)
                Text(verificationText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(badgeColor)
                Spacer()
            }

            if post.hasVideoProof {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Video proof available")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                    if let url = post.videoProofURL {
                        Link(destination: URL(string: url) ?? URL(string: "https://youtube.com")!) {
                            Text("Watch")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text("No video proof - Tip with caution")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Community votes
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                    Text("\(post.communityVotes)")
                        .font(.caption)
                }
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .foregroundColor(.red)
                    Text("\(post.communityDownvotes)")
                        .font(.caption)
                }
                Spacer()
                Text("Community verification")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var badgeColor: Color {
        switch post.verificationBadge {
        case .verified: return .blue
        case .videoProof: return .green
        case .communityVerified: return .orange
        case .unverified: return .gray
        }
    }

    private var verificationText: String {
        switch post.verificationBadge {
        case .verified: return "Fully Verified"
        case .videoProof: return "Video Verified"
        case .communityVerified: return "Community Verified"
        case .unverified: return "Unverified Post"
        }
    }

    private var recipientHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: post.userPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Tip to")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(post.userName)
                    .font(.headline)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("For cleanup")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", post.wasteCollectedKg)) kg collected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }

    private func paymentBreakdown(amount: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tip Amount")
                Spacer()
                Text("₹\(amount)")
            }
            .font(.subheadline)

            HStack {
                Text("Platform Fee (5%)")
                Spacer()
                Text("₹\(Int(Double(amount) * 0.05))")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack {
                Text("GST (18%)")
                Spacer()
                Text("₹\(Int(Double(amount) * 0.05 * 0.18))")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Divider()

            HStack {
                Text("Creator Receives")
                    .fontWeight(.semibold)
                Spacer()
                Text("₹\(Int(Double(amount) * 0.90))")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private func processTip() {
        guard let amount = tipAmount else { return }

        isProcessing = true

        Task {
            do {
                try await PaymentService.shared.createTip(
                    postId: post.id,
                    recipientId: post.userId,
                    amount: amount
                )
                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct AmountButton: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("₹\(amount)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.green : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
}

#Preview {
    TipSheet(post: Post.preview)
}
