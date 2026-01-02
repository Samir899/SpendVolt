import SwiftUI

struct SubscriptionsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var itemToDelete: RecurringTransaction?
    @State private var showDeleteConfirmation = false
    
    var totalMonthlyCommitment: Double {
        viewModel.recurringTransactions.reduce(0) { total, recurring in
            let monthlyAmount: Double
            switch recurring.frequency {
            case .daily: monthlyAmount = recurring.amount * 30
            case .weekly: monthlyAmount = recurring.amount * 4
            case .monthly: monthlyAmount = recurring.amount
            case .quarterly: monthlyAmount = recurring.amount / 3
            case .halfYearly: monthlyAmount = recurring.amount / 6
            case .yearly: monthlyAmount = recurring.amount / 12
            }
            return total + monthlyAmount
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if viewModel.recurringTransactions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // commitment Summary Card
                            commitmentSummaryCard
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Active Subscriptions")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 4)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.recurringTransactions) { recurring in
                                        SubscriptionRow(
                                            recurring: recurring,
                                            currencySymbol: viewModel.currencySymbol,
                                            categoryIcon: viewModel.categories.first(where: { $0.name == recurring.categoryName })?.icon ?? "calendar.badge.clock"
                                        ) {
                                            itemToDelete = recurring
                                            showDeleteConfirmation = true
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                itemToDelete = recurring
                                                showDeleteConfirmation = true
                                            } label: {
                                                Label("Cancel Subscription", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                if let id = recurring.id {
                                                    viewModel.deleteRecurringTransaction(id: id)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(Theme.horizontalPadding)
                    }
                }
            }
            .navigationTitle("Subscriptions & EMIs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog("Cancel Subscription?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Yes, Cancel It", role: .destructive) {
                    if let id = itemToDelete?.id {
                        viewModel.deleteRecurringTransaction(id: id)
                    }
                }
                Button("Keep It", role: .cancel) {}
            } message: {
                Text("This will stop future automatic entries for \(itemToDelete?.merchantName ?? "this subscription").")
            }
        }
    }
    
    private var commitmentSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Commitment")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(Theme.formatCurrency(totalMonthlyCommitment, symbol: viewModel.currencySymbol))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.primaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.secondaryBackground)
                    .frame(width: 120, height: 120)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundColor(Theme.textTertiary)
            }
            
            VStack(spacing: 8) {
                Text("Simplify your recurring payments")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Log your Netflix, Rent, or EMIs here to stay ahead of your budget.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct SubscriptionRow: View {
    let recurring: RecurringTransaction
    let currencySymbol: String
    let categoryIcon: String
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    
    var frequencyColor: Color {
        switch recurring.frequency {
        case .daily: return .blue
        case .weekly: return .purple
        case .monthly: return .green
        case .quarterly, .halfYearly: return .orange
        case .yearly: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal Header (Always Visible)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: categoryIcon)
                            .foregroundColor(Theme.primary)
                            .font(.system(size: 18))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recurring.merchantName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text(recurring.frequency.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Theme.formatCurrency(recurring.amount, symbol: currencySymbol))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .background(Theme.cardShadow)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        DetailItem(label: "Category", value: recurring.categoryName, icon: "tag.fill")
                        DetailItem(label: "Next Due Date", value: recurring.nextDueDate.formatted(date: .long, time: .omitted), icon: "calendar")
                        DetailItem(label: "Status", value: "Active", icon: "checkmark.circle.fill", valueColor: .green)
                    }
                    .padding(.horizontal, 16)
                    
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Cancel Subscription")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardShadow, lineWidth: 1)
        )
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = Theme.textPrimary
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

