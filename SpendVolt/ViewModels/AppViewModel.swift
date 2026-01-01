import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [UserCategory] = []
    @Published var profile: UserProfile
    
    private let storageService: StorageServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private let upiParser: UPIParserProtocol
    private let analyticsEngine: AnalyticsEngineProtocol
    
    init(storageService: StorageServiceProtocol = StorageService(), 
         paymentService: PaymentServiceProtocol = UPIPaymentService(),
         upiParser: UPIParserProtocol = UPIParser(),
         analyticsEngine: AnalyticsEngineProtocol = AnalyticsEngine()) {
        self.storageService = storageService
        self.paymentService = paymentService
        self.upiParser = upiParser
        self.analyticsEngine = analyticsEngine
        
        self.transactions = storageService.loadTransactions()
        self.categories = storageService.loadCategories()
        self.profile = storageService.loadProfile()
    }
    
    func saveTransactions() {
        storageService.saveTransactions(transactions)
    }
    
    func saveCategories() {
        storageService.saveCategories(categories)
    }

    func saveProfile() {
        storageService.saveProfile(profile)
    }
    
    func initiatePayment(merchantName: String, amount: String, categoryName: String, url: String, app: String) {
        let newTxn = Transaction(merchantName: merchantName, 
                               amount: amount, 
                               date: Date(), 
                               status: .pending, 
                               categoryName: categoryName)
        transactions.insert(newTxn, at: 0)
        saveTransactions()
        paymentService.openDirectApp(url: url, amount: amount, app: app)
    }
    
    func confirmTransaction(_ id: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].status = .success
            saveTransactions()
        }
    }
    
    func rejectTransaction(_ id: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].status = .failure
            saveTransactions()
        }
    }
    
    func deleteTransaction(_ id: UUID) {
        transactions.removeAll(where: { $0.id == id })
        saveTransactions()
    }
    
    func addCategory(name: String, icon: String) {
        let newCat = UserCategory(name: name, icon: icon)
        categories.append(newCat)
        saveCategories()
    }
    
    func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            moveTransactions(from: category.name, to: "Unassigned")
        }
        categories.remove(atOffsets: offsets)
        saveCategories()
    }
    
    func deleteCategory(id: UUID, replacementCategoryName: String? = nil) {
        if let category = categories.first(where: { $0.id == id }) {
            let targetName = replacementCategoryName ?? "Unassigned"
            moveTransactions(from: category.name, to: targetName)
            categories.removeAll(where: { $0.id == id })
            saveCategories()
        }
    }
    
    func moveTransactions(from oldName: String, to newName: String) {
        var modified = false
        for i in 0..<transactions.count {
            if transactions[i].categoryName == oldName {
                transactions[i].categoryName = newName
                modified = true
            }
        }
        if modified {
            saveTransactions()
        }
    }
    
    func countTransactions(for categoryName: String) -> Int {
        transactions.filter { $0.categoryName == categoryName }.count
    }
    
    func updateTransactionCategory(id: UUID, newCategoryName: String) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].categoryName = newCategoryName
            saveTransactions()
        }
    }
    
    func addManualTransaction(merchantName: String, amount: String, categoryName: String, date: Date) {
        let newTxn = Transaction(
            merchantName: merchantName,
            amount: amount,
            date: date,
            status: .success, // Manual transactions are assumed successful immediately
            categoryName: categoryName
        )
        transactions.insert(newTxn, at: 0)
        saveTransactions()
    }
    
    func parseUPI(url: String, key: String) -> String? {
        upiParser.parseUPI(url: url, key: key)
    }

    func getBestPayeeName(from url: String) -> String {
        upiParser.getBestPayeeName(from: url)
    }
    
    // MARK: - Statistics
    
    var totalSpentThisMonth: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        return analyticsEngine.calculateTotalSpent(transactions: transactions, month: currentMonth, year: currentYear)
    }
    
    var topThreeSpends: [Transaction] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        return analyticsEngine.calculateTopSpends(transactions: transactions, month: currentMonth, year: currentYear, limit: 3)
    }
    
    var dailyInsight: DailyInsight {
        analyticsEngine.calculateDailyInsight(totalSpent: totalSpentThisMonth, budget: profile.monthlyBudget)
    }
    
    // MARK: - Category Analytics
    
    enum AnalysisPeriod: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    func categorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        analyticsEngine.calculateCategorySpending(transactions: transactions, categories: categories, period: period)
    }
    
    func groupedCategorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        let allSpending = categorySpending(for: period)
        // If we have 5 or fewer categories, show them all.
        // If we have 6 or more, show the Top 5 and group the rest.
        if allSpending.count <= 5 { return allSpending }
        
        let topFive = Array(allSpending.prefix(5))
        let remaining = allSpending.dropFirst(5)
        
        let othersTotal = remaining.reduce(0) { $0 + $1.totalAmount }
        let othersPercentage = remaining.reduce(0) { $0 + $1.percentage }
        
        let others = CategorySpending(
            categoryName: "Others",
            totalAmount: othersTotal,
            percentage: othersPercentage,
            icon: "ellipsis.circle.fill"
        )
        
        var finalResult = topFive
        finalResult.append(others)
        return finalResult
    }
    
    var categorySpendingThisMonth: [CategorySpending] {
        categorySpending(for: .month)
    }
}

