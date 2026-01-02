import SwiftUI

struct SubscriptionsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if viewModel.recurringTransactions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.recurringTransactions) { recurring in
                                SubscriptionRow(recurring: recurring, currencySymbol: viewModel.currencySymbol) {
                                    if let id = recurring.id {
                                        viewModel.deleteRecurringTransaction(id: id)
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
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 70, weight: .thin))
                .foregroundColor(Theme.textTertiary)
            
            VStack(spacing: 8) {
                Text("No Subscriptions")
                    .font(.title2.bold())
                
                Text("Add recurring expenses like Netflix, Rent, or EMI in the Manual Entry screen.")
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
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(Theme.primary)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.merchantName)
                    .font(.system(size: 16, weight: .bold))
                
                HStack {
                    Text(recurring.frequency.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.secondaryBackground)
                        .cornerRadius(4)
                    
                    Text("Next: \(recurring.nextDueDate, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Theme.formatCurrency(recurring.amount, symbol: currencySymbol))
                    .font(.system(size: 17, weight: .bold))
                
                Button(role: .destructive, action: onDelete) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .bold))
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
    }
}

