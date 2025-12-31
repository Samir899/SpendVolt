import SwiftUI

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable, Equatable {
    var id = UUID()
    let merchantName: String
    let amount: String
    let date: Date
    var status: TransactionStatus
    
    enum TransactionStatus: String, Codable, Equatable {
        case pending, success, failure
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @AppStorage("saved_transactions") private var transactionsData: Data = Data()
    @State private var transactions: [Transaction] = []
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(transactions: $transactions)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView(transactions: $transactions)
                .tabItem {
                    Label("Expenses", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            Text("Settings Screen Coming Soon")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(.orange)
        .onAppear(perform: loadTransactions)
        .onChange(of: transactions) {
            saveTransactions()
        }
    }
    
    func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            transactionsData = encoded
        }
    }
    
    func loadTransactions() {
        if let decoded = try? JSONDecoder().decode([Transaction].self, from: transactionsData) {
            transactions = decoded
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Binding var transactions: [Transaction]
    
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showPaymentSheet = false
    @State private var paymentAmount: String = ""
    @State private var processingTransaction: Transaction?
    @State private var isProcessingPayment = false
    
    var merchantName: String {
        guard let code = scannedCode else { return "" }
        return parseUPI(url: code, key: "pn") ?? "Merchant"
    }
    
    var pendingTransactions: [Transaction] {
        transactions.filter { $0.status == .pending }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SpendVolt")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.orange)
                            Text("ENERGY EXPENSE TRACKER")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()

                        // PENDING ACTIONS
                        if !pendingTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pending Confirmations")
                                    .font(.headline)
                                
                                ForEach(pendingTransactions) { txn in
                                    PendingCard(transaction: txn, onConfirm: {
                                        startReconfirmation(for: txn)
                                    }, onDelete: {
                                        deleteTransaction(txn)
                                    })
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.05))
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                        
                        // MAIN SCAN BUTTON
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange.opacity(0.1), .orange.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 200, height: 200)
                                
                                Image(systemName: "qrcode.viewfinder")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.orange)
                            }
                            
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Scan to Pay")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 40)
                                .background(Color.orange)
                                .clipShape(Capsule())
                                .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
                            }
                        }
                        .padding(.top, 40)
                    }
                }
            }
            .blur(radius: isProcessingPayment ? 5 : 0)
            
            if isProcessingPayment, let txn = processingTransaction {
                ProcessingOverlay(
                    transaction: txn,
                    onVerify: { confirmTransaction(txn) },
                    onFail: { rejectTransaction(txn) },
                    onWait: { withAnimation { self.isProcessingPayment = false } }
                )
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            ScannerView { result in
                self.scannedCode = result
                self.isShowingScanner = false
                if let qrAmount = parseUPI(url: result, key: "am") {
                    self.paymentAmount = qrAmount
                } else {
                    self.paymentAmount = ""
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showPaymentSheet = true
                }
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            PaymentBottomSheet(merchantName: merchantName, amount: $paymentAmount) { appName in
                if let code = scannedCode {
                    self.showPaymentSheet = false
                    initiatePayment(url: code, app: appName)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // Logic functions for HomeView
    func initiatePayment(url: String, app: String) {
        let newTxn = Transaction(merchantName: merchantName, amount: paymentAmount, date: Date(), status: .pending)
        transactions.insert(newTxn, at: 0)
        self.processingTransaction = newTxn
        withAnimation { self.isProcessingPayment = true }
        openDirectApp(url: url, app: app)
    }
    
    func startReconfirmation(for txn: Transaction) {
        self.processingTransaction = txn
        withAnimation { self.isProcessingPayment = true }
    }
    
    func confirmTransaction(_ txn: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == txn.id }) {
            transactions[index].status = .success
        }
        withAnimation {
            self.isProcessingPayment = false
            self.processingTransaction = nil
        }
    }
    
    func rejectTransaction(_ txn: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == txn.id }) {
            transactions[index].status = .failure
        }
        withAnimation {
            self.isProcessingPayment = false
            self.processingTransaction = nil
        }
    }
    
    func deleteTransaction(_ txn: Transaction) {
        transactions.removeAll(where: { $0.id == txn.id })
    }
    
    func parseUPI(url: String, key: String) -> String? {
        guard let urlComponents = URLComponents(string: url),
              let queryItems = urlComponents.queryItems else { return nil }
        return queryItems.first(where: { $0.name == key })?.value?.replacingOccurrences(of: "+", with: " ")
    }

    func openDirectApp(url: String, app: String) {
        guard let payload = url.components(separatedBy: "?").last else { return }
        let amParam = paymentAmount.isEmpty ? "" : "&am=\(paymentAmount)"
        var targetURL = ""
        switch app {
        case "Google Pay": targetURL = "tez://upi/pay?\(payload)\(amParam)"
        case "PhonePe": targetURL = "phonepe://pay?\(payload)\(amParam)"
        case "Paytm": targetURL = "paytmmp://pay?\(payload)\(amParam)"
        default: targetURL = url
        }
        if let gpayURL = URL(string: targetURL) {
            UIApplication.shared.open(gpayURL)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @Binding var transactions: [Transaction]
    
    var completedTransactions: [Transaction] {
        transactions.filter { $0.status != .pending }
    }

    var body: some View {
        NavigationStack {
            List {
                if completedTransactions.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No Expense History")
                            .font(.headline)
                        Text("Your fuel and energy payments will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(completedTransactions) { txn in
                        HistoryRow(transaction: txn)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Expense History")
        }
    }
}

// MARK: - Components

struct PendingCard: View {
    let transaction: Transaction
    let onConfirm: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.merchantName)
                    .font(.subheadline.bold())
                Text("₹\(transaction.amount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: onDelete) {
                    Image(systemName: "trash").foregroundColor(.red.opacity(0.7)).padding(8)
                }
                Button(action: onConfirm) {
                    Text("Verify").font(.caption.bold()).foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 16).background(Color.orange).cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct HistoryRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(transaction.status == .success ? .green : .red)
            VStack(alignment: .leading) {
                Text(transaction.merchantName)
                    .font(.subheadline.bold())
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("₹\(transaction.amount)")
                .font(.subheadline.bold())
                .strikethrough(transaction.status == .failure)
                .foregroundColor(transaction.status == .failure ? .secondary : .primary)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

struct ProcessingOverlay: View {
    let transaction: Transaction
    let onVerify: () -> Void
    let onFail: () -> Void
    let onWait: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 25) {
                ProgressView().scaleEffect(1.5).tint(.orange)
                Text("Verify Payment").font(.headline)
                Text("Did you finish paying ₹\(transaction.amount) at \(transaction.merchantName)?")
                    .font(.subheadline).multilineTextAlignment(.center).foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    Button(action: onVerify) {
                        Text("Yes").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.orange).cornerRadius(12)
                    }
                    Button(action: onFail) {
                        Text("No").font(.headline).foregroundColor(.red).frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).cornerRadius(12)
                    }
                    Button("I'll check later") { onWait() }.font(.caption).foregroundColor(.gray).padding(.top, 5)
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemBackground)))
            .padding(.horizontal, 40)
        }
    }
}

struct PaymentBottomSheet: View {
    let merchantName: String
    @Binding var amount: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 8) {
                Text("Paying to").font(.caption.bold()).foregroundColor(.secondary)
                Text(merchantName).font(.title3.bold())
            }
            .padding(.top, 30)
            
            VStack(spacing: 10) {
                Text("ENTER AMOUNT").font(.caption2.bold()).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("₹").font(.system(size: 40, weight: .bold)).foregroundColor(.primary)
                    TextField("0", text: $amount).keyboardType(.decimalPad).font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            .padding(.horizontal)
            Divider()
            VStack(spacing: 15) {
                Text("SELECT PAYMENT APP").font(.caption2.bold()).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                VStack(spacing: 0) {
                    PaymentRow(name: "Google Pay", icon: "tez") { onSelect("Google Pay") }
                    Divider().padding(.leading, 60)
                    PaymentRow(name: "PhonePe", icon: "phonepe") { onSelect("PhonePe") }
                    Divider().padding(.leading, 60)
                    PaymentRow(name: "Paytm", icon: "paytm") { onSelect("Paytm") }
                }
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(15)
                .padding(.horizontal)
            }
            Spacer()
        }
    }
}

struct PaymentRow: View {
    let name: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Circle().fill(Color.orange.opacity(0.1)).frame(width: 35, height: 35).overlay(Text(name.prefix(1)).font(.system(size: 16, weight: .bold)).foregroundColor(.orange))
                Text(name).font(.body.bold()).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
