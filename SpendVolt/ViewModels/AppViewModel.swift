import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var pendingTransactions: [Transaction] = []
    @Published var totalSpentThisMonth: Double = 0
    @Published var topThreeSpends: [Transaction] = []
    @Published var dailyInsight: DailyInsight = DailyInsight(allowance: 0, isOverPace: false, paceDifference: 0)
    @Published var categories: [UserCategory] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    
    @Published var profile: UserProfile
    @Published var isLoading = false
    @Published var errorMessage: String? {
        didSet {
            if errorMessage != nil {
                showErrorAlert = true
            }
        }
    }
    @Published var showErrorAlert = false
    @Published var isAuthenticated = false
    
    var currencySymbol: String {
        profile.currency.rawValue
    }
    
    func formatCurrency(_ amount: Double) -> String {
        Theme.formatCurrency(amount, symbol: currencySymbol)
    }
    
    private let storageService: StorageServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let upiParser: UPIParserProtocol
    private let analyticsEngine: AnalyticsEngineProtocol
    private let sessionManager: SessionManagerProtocol
    
    var cancellables = Set<AnyCancellable>()
    private var idMap: [String: String] = [:] // tempId -> realId mapping
    
    init(storageService: StorageServiceProtocol = StorageService(), 
         paymentService: PaymentServiceProtocol = UPIPaymentService(),
         networkService: NetworkServiceProtocol = NetworkService(),
         upiParser: UPIParserProtocol = UPIParser(),
         analyticsEngine: AnalyticsEngineProtocol = AnalyticsEngine(),
         sessionManager: SessionManagerProtocol = SessionManager.shared,
         initialDashboard: AppDashboard? = nil) {
        self.storageService = storageService
        self.paymentService = paymentService
        self.networkService = networkService
        self.upiParser = upiParser
        self.analyticsEngine = analyticsEngine
        self.sessionManager = sessionManager
        
        // 1. Load from local cache first
        self.transactions = storageService.loadTransactions()
        self.categories = storageService.loadCategories()
        self.profile = storageService.loadProfile()
        
        self.isAuthenticated = sessionManager.isAuthenticated
        
        setupBindings()
        
        // 2. If we received a dashboard immediately from login, apply it now
        if let dashboard = initialDashboard {
            applyDashboard(dashboard)
        }
        
        // 3. Sync with backend for any fresh changes
        if isAuthenticated {
            syncWithBackend()
        }
    }
    
    private func setupBindings() {
        // Automatically update pending transactions whenever transactions change
        $transactions
            .map { $0.filter { $0.status == .pending } }
            .assign(to: &$pendingTransactions)
    }
    
    func syncWithBackend() {
        guard isAuthenticated else { return }
        
        networkService.fetchDashboard()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    if (error as? NetworkError) == .unauthorized {
                        self?.logout()
                    }
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
            
        fetchRecurringTransactions()
    }

    func fetchRecurringTransactions() {
        networkService.fetchRecurringTransactions()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch recurring: \(error)")
                }
            } receiveValue: { [weak self] recurring in
                self?.recurringTransactions = recurring
            }
            .store(in: &cancellables)
    }

    func addRecurringTransaction(merchantName: String, amount: String, categoryName: String, frequency: RecurrenceFrequency, startDate: Date) {
        let doubleAmount = Double(amount) ?? 0.0
        let newRecurring = RecurringTransaction(
            merchantName: merchantName,
            amount: doubleAmount,
            categoryName: categoryName,
            frequency: frequency,
            nextDueDate: startDate
        )
        
        networkService.createRecurringTransaction(newRecurring)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] saved in
                self?.recurringTransactions.append(saved)
            }
            .store(in: &cancellables)
    }

    func deleteRecurringTransaction(id: String) {
        networkService.deleteRecurringTransaction(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.recurringTransactions.removeAll(where: { $0.id == id })
            }
            .store(in: &cancellables)
    }

    func applyDashboard(_ dashboard: AppDashboard) {
        self.objectWillChange.send()
        
        if self.transactions != dashboard.transactions { self.transactions = dashboard.transactions }
        
        // Merge or replace categories carefully
        if self.categories != dashboard.categories {
            self.categories = dashboard.categories
        }
        
        self.profile = dashboard.profile
        
        self.totalSpentThisMonth = dashboard.stats.totalSpentThisMonth
        self.topThreeSpends = dashboard.stats.topThreeSpends
        self.dailyInsight = dashboard.stats.dailyInsight
        
        self.isAuthenticated = true
        
        saveTransactions()
        saveCategories()
        storageService.saveProfile(profile)
    }

    func logout() {
        sessionManager.clearSession()
        isAuthenticated = false
        transactions = []
        categories = UserCategory.defaults
    }
    
    func saveTransactions() {
        storageService.saveTransactions(transactions)
    }
    
    func saveCategories() {
        storageService.saveCategories(categories)
    }

    func saveProfile() {
        storageService.saveProfile(profile)
        networkService.updateProfile(profile)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    @discardableResult
    func initiatePayment(merchantName: String, amount: String, categoryName: String, url: String, app: String) -> String {
        let tempId = UUID().uuidString
        let doubleAmount = Double(amount) ?? 0.0
        let newTxn = Transaction(id: tempId,
                               merchantName: merchantName, 
                               amount: doubleAmount, 
                               date: Date(), 
                               status: .pending, 
                               categoryName: categoryName)
        
        self.transactions.insert(newTxn, at: 0)
        
        networkService.createTransaction(newTxn)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.transactions.removeAll(where: { $0.id == tempId })
                }
            } receiveValue: { [weak self] savedTxn in
                self?.idMap[tempId] = savedTxn.id
                
                var finalTxn = savedTxn
                if let localIndex = self?.transactions.firstIndex(where: { $0.id == tempId }),
                   self?.transactions[localIndex].status == .success {
                    finalTxn.status = .success
                    if let realId = Int(savedTxn.id) {
                        self?.networkService.updateTransactionStatus(id: realId, status: AppConstants.TransactionStatus.success.rawValue)
                            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                            .store(in: &(self!.cancellables))
                    }
                }

                if let index = self?.transactions.firstIndex(where: { $0.id == tempId }) {
                    self?.transactions[index] = finalTxn
                }
                self?.saveTransactions()
            }
            .store(in: &cancellables)

        paymentService.openDirectApp(url: url, amount: amount, app: app)
        return tempId
    }
    
    func confirmTransaction(_ id: String, finalAmount: Double? = nil) {
        let currentId = idMap[id] ?? id
        if let index = transactions.firstIndex(where: { $0.id == currentId }) {
            if let amount = finalAmount {
                transactions[index].amount = amount
            }
            transactions[index].status = .success
            saveTransactions()
            
            if let intId = Int(currentId) {
                let status = AppConstants.TransactionStatus.success.rawValue
                // If amount changed, we might need a separate API call or a more robust update
                // For now, update status and local amount.
                networkService.updateTransactionStatus(id: intId, status: status)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                        self?.refreshStats()
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    func rejectTransaction(_ id: String) {
        let currentId = idMap[id] ?? id
        if let index = transactions.firstIndex(where: { $0.id == currentId }) {
            transactions[index].status = .failure
            saveTransactions()
            
            if let intId = Int(currentId) {
                networkService.updateTransactionStatus(id: intId, status: AppConstants.TransactionStatus.failure.rawValue)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                        self?.refreshStats()
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    func deleteTransaction(_ id: String) {
        let currentId = idMap[id] ?? id
        transactions.removeAll(where: { $0.id == id || $0.id == currentId })
        saveTransactions()
        
        if let intId = Int(currentId) {
            networkService.deleteTransaction(id: intId)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.refreshStats()
                })
                .store(in: &cancellables)
        } else {
            refreshStats()
        }
    }
    
    func addCategory(name: String, icon: String) {
        let newCat = UserCategory(name: name, icon: icon, type: "EXPENSE")
        
        networkService.createCategory(newCat)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] savedCat in
                self?.categories.append(savedCat)
                self?.saveCategories()
            })
            .store(in: &cancellables)
    }
    
    func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if let id = category.id {
                networkService.deleteCategory(id: id)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &cancellables)
            }
            moveTransactions(from: category.name, to: AppConstants.Category.unassigned)
        }
        categories.remove(atOffsets: offsets)
        saveCategories()
    }
    
    func deleteCategory(id: Int?, replacementCategoryName: String? = nil) {
        guard let id = id else { return }
        if let category = categories.first(where: { $0.id == id }) {
            networkService.deleteCategory(id: id)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &cancellables)
                
            let targetName = replacementCategoryName ?? AppConstants.Category.unassigned
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
    
    func updateTransactionCategory(id: String, newCategoryName: String) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].categoryName = newCategoryName
            saveTransactions()
            
            if let intId = Int(id) {
                networkService.updateTransactionCategory(id: intId, categoryName: newCategoryName)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                        self?.refreshStats()
                    })
                    .store(in: &cancellables)
            }
        }
    }
    
    func addManualTransaction(merchantName: String, amount: String, categoryName: String, date: Date) {
        let tempId = UUID().uuidString
        let doubleAmount = Double(amount) ?? 0.0
        let newTxn = Transaction(
            id: tempId,
            merchantName: merchantName,
            amount: doubleAmount,
            date: date,
            status: .success,
            categoryName: categoryName
        )
        
        self.transactions.insert(newTxn, at: 0)
        
        networkService.createTransaction(newTxn)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.transactions.removeAll(where: { $0.id == tempId })
                }
            } receiveValue: { [weak self] savedTxn in
                self?.idMap[tempId] = savedTxn.id
                if let index = self?.transactions.firstIndex(where: { $0.id == tempId }) {
                    self?.transactions[index] = savedTxn
                }
                self?.saveTransactions()
                self?.refreshStats()
            }
            .store(in: &cancellables)
    }

    private func refreshStats() {
        networkService.fetchDashboard()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Dashboard refresh failed: \(error)")
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
    }
    
    func parseUPI(url: String, key: String) -> String? {
        upiParser.parseUPI(url: url, key: key)
    }

    func validateQR(url: String) -> QRType {
        upiParser.validateQR(url: url)
    }

    func getBestPayeeName(from url: String) -> String {
        upiParser.getBestPayeeName(from: url)
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

