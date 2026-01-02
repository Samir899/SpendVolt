import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    @State private var isShowingScanner = false
    @State private var paymentIntent: PaymentIntent?
    @State private var paymentAmount: String = ""
    @State private var selectedCategoryName: String = "Fuel"
    @State private var processingTransaction: Transaction?
    @State private var isProcessingPayment = false
    @State private var isShowingProfile = false
    @State private var isShowingManualEntry = false
    @State private var transactionToDelete: String?
    @State private var isShowingDeleteConfirmation = false
    
    struct PaymentIntent: Identifiable {
        let id = UUID()
        let code: String
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: - Header
                        HomeHeaderView(userName: viewModel.profile.name) {
                            isShowingProfile = true
                        }
                        
                        // MARK: - Main Summary & Scan Action (Centerpiece)
                        VStack(spacing: 40) {
                            HomeSummaryCard(
                                spent: viewModel.totalSpentThisMonth,
                                budget: viewModel.profile.monthlyBudget,
                                currencySymbol: viewModel.currencySymbol,
                                threshold: viewModel.profile.budgetWarningThreshold * viewModel.profile.monthlyBudget,
                                insight: viewModel.dailyInsight
                            )
                            
                            ScanActionCard {
                                isShowingScanner = true
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // MARK: - Top Spends Section
                        if !viewModel.topThreeSpends.isEmpty {
                            TopSpendsList(
                                topSpends: viewModel.topThreeSpends,
                                currencySymbol: viewModel.currencySymbol,
                                categories: viewModel.categories
                            )
                        }
                        
                        // MARK: - Pending Actions
                        if !viewModel.pendingTransactions.isEmpty {
                            PendingConfirmationsList(
                                transactions: viewModel.pendingTransactions,
                                currencySymbol: viewModel.currencySymbol,
                                categories: viewModel.categories,
                                onUpdateCategory: { id, category in
                                    viewModel.updateTransactionCategory(id: id, newCategoryName: category)
                                },
                                onConfirm: { txn in
                                    startReconfirmation(for: txn)
                                },
                                onDelete: { id in
                                    self.transactionToDelete = id
                                    self.isShowingDeleteConfirmation = true
                                }
                            )
                        }
                        
                        Spacer(minLength: 100) // Extra space for FAB
                    }
                    .padding(.bottom, 20)
                }
                .disabled(isProcessingPayment)
                
                // Floating Action Button
                Button {
                    isShowingManualEntry = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 64, height: 64)
                            .shadow(color: Theme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
                
                if isProcessingPayment, let txn = processingTransaction {
                    ProcessingOverlay(
                        transaction: txn,
                        currencySymbol: viewModel.currencySymbol,
                        onVerify: { 
                            viewModel.confirmTransaction(txn.id)
                            withAnimation(.spring()) { self.isProcessingPayment = false }
                        },
                        onFail: { 
                            viewModel.rejectTransaction(txn.id)
                            withAnimation(.spring()) { self.isProcessingPayment = false }
                        },
                        onWait: { withAnimation(.spring()) { self.isProcessingPayment = false } }
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1)
                }
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            ScannerView { result in
                self.isShowingScanner = false
                
                if let qrAmount = viewModel.parseUPI(url: result, key: "am") {
                    self.paymentAmount = qrAmount
                } else {
                    self.paymentAmount = ""
                }
                
                // Small delay to ensure scanner is fully dismissed before showing payment sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.paymentIntent = PaymentIntent(code: result)
                }
            }
        }
        .sheet(item: $paymentIntent) { intent in
            PaymentBottomSheet(
                viewModel: viewModel,
                scannedCode: intent.code,
                amount: $paymentAmount,
                selectedCategoryName: $selectedCategoryName
            ) { appName in
                self.paymentIntent = nil
                
                let finalName = viewModel.getBestPayeeName(from: intent.code)
                
                let tempId = viewModel.initiatePayment(
                    merchantName: finalName,
                    amount: paymentAmount,
                    categoryName: selectedCategoryName,
                    url: intent.code,
                    app: appName
                )
                
                if let newTxn = viewModel.transactions.first(where: { $0.id == tempId }) {
                    self.processingTransaction = newTxn
                    withAnimation(.spring()) { self.isProcessingPayment = true }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingProfile) {
            ProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingManualEntry) {
            ManualExpenseSheet(viewModel: viewModel)
        }
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
    }
    
    func startReconfirmation(for txn: Transaction) {
        self.processingTransaction = txn
        withAnimation(.spring()) { self.isProcessingPayment = true }
    }
}
