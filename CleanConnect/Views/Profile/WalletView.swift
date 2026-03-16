// WalletView.swift
// Wallet & Payments management - Stripe Connect onboarding and balance

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var userState: UserState
    @StateObject private var viewModel = WalletViewModel()
    @State private var showOnboardingAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Balance Card
                balanceCard

                // Creator Status Card
                creatorStatusCard

                // Quick Actions
                quickActionsSection

                // Recent Transactions
                recentTransactionsSection

                // Info Section
                infoSection
            }
            .padding()
        }
        .navigationTitle("Wallet & Payments")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadWalletData()
        }
        .refreshable {
            await viewModel.loadWalletData()
        }
        .alert("Set Up Payments", isPresented: $showOnboardingAlert) {
            Button("Continue") {
                Task {
                    await viewModel.startOnboarding()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be redirected to Stripe to set up your payment account. This allows you to receive tips from the community.")
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("₹\(viewModel.balance)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }

            Divider()

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips Received")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(userState.currentUser?.tipsReceived ?? 0)")
                        .font(.headline)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tips Given")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(userState.currentUser?.tipsGiven ?? 0)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Creator Status Card

    private var creatorStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Creator Payments")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if viewModel.canReceivePayments {
                // Active creator status
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready to Receive Tips")
                            .font(.subheadline.weight(.medium))
                        Text("Your Stripe account is active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Button {
                    Task {
                        await viewModel.openDashboard()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("View Stripe Dashboard")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
            } else if viewModel.hasStripeAccount {
                // Incomplete onboarding
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Setup Incomplete")
                            .font(.subheadline.weight(.medium))
                        Text("Complete your Stripe onboarding to receive tips")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Button {
                    Task {
                        await viewModel.startOnboarding()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Complete Setup")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            } else {
                // No account
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start Earning Tips")
                            .font(.subheadline.weight(.medium))
                        Text("Set up your payment account to receive tips from the community")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Button {
                    showOnboardingAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Set Up Payments")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var statusBadge: some View {
        Group {
            if viewModel.canReceivePayments {
                Text("Active")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            } else if viewModel.hasStripeAccount {
                Text("Pending")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(6)
            } else {
                Text("Not Set Up")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(6)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.down.circle.fill",
                    title: "Withdraw",
                    color: .green,
                    enabled: viewModel.canReceivePayments
                ) {
                    Task {
                        await viewModel.openDashboard()
                    }
                }

                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    color: .blue,
                    enabled: true
                ) {
                    // Show transaction history
                }

                QuickActionButton(
                    icon: "questionmark.circle.fill",
                    title: "Help",
                    color: .purple,
                    enabled: true
                ) {
                    // Show help
                }
            }
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Button("See All") {}
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            if viewModel.recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No transactions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tips you send or receive will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.headline)

            VStack(spacing: 16) {
                InfoRow(
                    icon: "hand.thumbsup.fill",
                    title: "Post Cleanups",
                    description: "Share your cleanup efforts with video proof"
                )

                InfoRow(
                    icon: "indianrupeesign.circle.fill",
                    title: "Receive Tips",
                    description: "Community members can tip your good work"
                )

                InfoRow(
                    icon: "building.columns.fill",
                    title: "Get Paid",
                    description: "Withdraw to your bank via Stripe (93% to you, 7% platform fee)"
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Fee disclosure
            Text("Platform fee: 7% | Stripe processing fees may apply")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(enabled ? color : .gray)
                Text(title)
                    .font(.caption)
                    .foregroundColor(enabled ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .disabled(!enabled)
    }
}

struct TransactionRow: View {
    let transaction: WalletTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.isIncoming ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                .font(.title2)
                .foregroundColor(transaction.isIncoming ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.subheadline.weight(.medium))
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(transaction.isIncoming ? "+" : "-")₹\(transaction.amount)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(transaction.isIncoming ? .green : .primary)
        }
        .padding()
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - View Model

@MainActor
class WalletViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var hasStripeAccount = false
    @Published var canReceivePayments = false
    @Published var balance: Int = 0
    @Published var recentTransactions: [WalletTransaction] = []
    @Published var errorMessage: String?

    func loadWalletData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Check Stripe status
            try await StripeService.shared.checkConnectStatus()
            hasStripeAccount = StripeService.shared.hasStripeAccount
            canReceivePayments = StripeService.shared.canReceivePayments

            // Calculate balance from user stats
            if let user = await UserState.shared.currentUser {
                balance = user.tipsReceived - user.tipsGiven
            }

            // Load recent transactions (from local data for now)
            await loadTransactions()
        } catch {
            // Don't show error - just use default values
        }
    }

    func loadTransactions() async {
        // TODO: Load from Firestore tips collection
        // For now, this shows empty state
        recentTransactions = []
    }

    func startOnboarding() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let url = try await StripeService.shared.startConnectOnboarding()
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openDashboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let url = try await StripeService.shared.getDashboardLink()
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Transaction Model

struct WalletTransaction: Identifiable {
    let id: String
    let title: String
    let amount: Int
    let isIncoming: Bool
    let date: Date
    let status: String
}

#Preview {
    NavigationStack {
        WalletView()
            .environmentObject(UserState.shared)
    }
}
