import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingAnalytics = false
    @State private var selectedPeriod: AppViewModel.AnalysisPeriod = .month
    @State private var transactionToDelete: String?
    @State private var isShowingDeleteConfirmation = false
    
    var completedTransactions: [Transaction] {
        viewModel.transactions.filter { $0.status != .pending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if completedTransactions.isEmpty {
                    emptyStateView
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
                            
                            // Transactions List
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Transactions")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .padding(.horizontal, Theme.horizontalPadding)
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(completedTransactions) { txn in
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
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 70, weight: .thin))
                .foregroundColor(Theme.textTertiary)
            
            VStack(spacing: 8) {
                Text("No History Yet")
                    .font(.title2.bold())
                
                Text("Your completed payments will appear here.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
