import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingAnalytics = false
    @State private var selectedPeriod: AnalysisPeriod = .month
    @State private var transactionToDelete: String?
    @State private var isShowingDeleteConfirmation = false
    @State private var showOnlySuccess = false
    
    var filteredTransactions: [Transaction] {
        let base = viewModel.transactions.filter { $0.status != .pending }
        if showOnlySuccess {
            return base.filter { $0.status == .success }
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if filteredTransactions.isEmpty && !showOnlySuccess {
                    VStack(spacing: 24) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 70, weight: .thin))
                            .foregroundColor(Theme.textTertiary)
                        
                        VStack(spacing: 8) {
                            Text("No Transactions This Month")
                                .font(.title2.bold())
                            
                            Text("Your completed payments for \(Date().formatted(.dateTime.month(.wide).year())) will appear here.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Analytics Section
                            if showingAnalytics {
                                AnalyticsSection(
                                    selectedPeriod: $selectedPeriod,
                                    currencySymbol: viewModel.currencySymbol,
                                    fullSpendingData: viewModel.categorySpending(for: selectedPeriod),
                                    chartData: viewModel.groupedCategorySpending(for: selectedPeriod),
                                    categories: viewModel.categories
                                )
                                .padding(.top, 10)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Filters and List Header
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Transactions")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    
                                    Spacer()
                                    
                                    Toggle(isOn: $showOnlySuccess.animation(.spring())) {
                                        Text("Success Only")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
                                    .labelsHidden()
                                    
                                    Text("Success Only")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.horizontal, Theme.horizontalPadding)
                                
                                if filteredTransactions.isEmpty && showOnlySuccess {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(Theme.textTertiary)
                                        Text("No successful transactions found.")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(filteredTransactions) { txn in
                                            HistoryRow(
                                                transaction: txn,
                                                currencySymbol: viewModel.currencySymbol,
                                                categories: viewModel.categories
                                            ) { newCategory in
                                                withAnimation {
                                                    viewModel.updateTransactionCategory(id: txn.id, newCategoryName: newCategory)
                                                }
                                            }
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    self.transactionToDelete = txn.id
                                                    self.isShowingDeleteConfirmation = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.horizontalPadding)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Expense History")
            .alert("Delete Transaction", isPresented: $isShowingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let id = transactionToDelete {
                        viewModel.deleteTransaction(id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction? This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring()) {
                            showingAnalytics.toggle()
                        }
                    } label: {
                        Image(systemName: showingAnalytics ? "chart.bar.xaxis.ascending" : "chart.bar.xaxis")
                            .foregroundColor(Theme.primary)
                    }
                }
            }
        }
    }
}
