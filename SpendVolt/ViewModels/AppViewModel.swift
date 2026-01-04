import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    // MARK: - State
    @Published var transactions: [Transaction] = []
    @Published var pendingTransactions: [Transaction] = []
    @Published var totalSpentThisMonth: Double = 0
    @Published var topThreeSpends: [Transaction] = []
    @Published var dailyInsight: DailyInsight = DailyInsight(allowance: 0, isOverPace: false, paceDifference: 0)
    @Published var categories: [UserCategory] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var profile: UserProfile
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String? {
        didSet {
            if errorMessage != nil {
                showErrorAlert = true
            }
        }
    }
    @Published var showErrorAlert = false
    
    // MARK: - Managers (SRP)
    private let state: AppState
    private let transactionManager: TransactionManager
    private let categoryManager: CategoryManager
    private let profileManager: ProfileManager
    private let syncManager: SyncManager
    private let analyticsManager: AnalyticsManager
    
    // MARK: - Utilities
    private let upiParser: UPIParserProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var currencySymbol: String { profile.currency.rawValue }
    
    init(storageService: StorageServiceProtocol = StorageService(), 
         paymentService: PaymentServiceProtocol = UPIPaymentService(),
         networkService: NetworkServiceProtocol = NetworkService(),
         upiParser: UPIParserProtocol = UPIParser(),
         analyticsEngine: AnalyticsEngineProtocol = AnalyticsEngine(),
         sessionManager: SessionManagerProtocol = SessionManager.shared,
         initialDashboard: AppDashboard? = nil) {
        
        self.upiParser = upiParser
        
        // 1. Initialize State
        let initialProfile = storageService.loadProfile()
        let appState = AppState(profile: initialProfile)
        appState.transactions = storageService.loadTransactions()
        appState.categories = storageService.loadCategories()
        appState.recurringTransactions = storageService.loadRecurringTransactions()
        appState.isAuthenticated = sessionManager.isAuthenticated
        self.state = appState
        self.profile = initialProfile // Initial sync
        
        // 2. Initialize Managers
        self.transactionManager = TransactionManager(state: appState, networkService: networkService, storageService: storageService, paymentService: paymentService)
        self.categoryManager = CategoryManager(state: appState, networkService: networkService, storageService: storageService)
        self.profileManager = ProfileManager(state: appState, networkService: networkService, storageService: storageService, sessionManager: sessionManager)
        self.syncManager = SyncManager(state: appState, networkService: networkService, storageService: storageService)
        self.analyticsManager = AnalyticsManager(state: appState, analyticsEngine: analyticsEngine)
        
        // 3. Setup Bindings (State -> ViewModel)
        setupStateBindings()
        
        // 4. Setup Manager Callbacks
        let applyDashboardClosure: (AppDashboard) -> Void = { [weak self] dashboard in
            self?.syncManager.applyDashboard(dashboard)
        }
        
        self.transactionManager.onDashboardReceived = applyDashboardClosure
        self.categoryManager.onDashboardReceived = applyDashboardClosure
        self.profileManager.onDashboardReceived = applyDashboardClosure
        
        // 5. Initial Data Loading
        if let dashboard = initialDashboard {
            syncManager.applyDashboard(dashboard)
        }
        
        if appState.isAuthenticated {
            syncManager.syncWithBackend()
        }
    }
    
    private func setupStateBindings() {
        state.$transactions.assign(to: &$transactions)
        state.$pendingTransactions.assign(to: &$pendingTransactions)
        state.$totalSpentThisMonth.assign(to: &$totalSpentThisMonth)
        state.$topThreeSpends.assign(to: &$topThreeSpends)
        state.$dailyInsight.assign(to: &$dailyInsight)
        state.$categories.assign(to: &$categories)
        state.$recurringTransactions.assign(to: &$recurringTransactions)
        state.$profile.assign(to: &$profile)
        state.$isAuthenticated.assign(to: &$isAuthenticated)
        state.$isLoading.assign(to: &$isLoading)
        state.$errorMessage.assign(to: &$errorMessage)
        state.$showErrorAlert.assign(to: &$showErrorAlert)
    }
    
    // MARK: - Public API (Delegation)
    
    func formatCurrency(_ amount: Double) -> String {
        Theme.formatCurrency(amount, symbol: currencySymbol)
    }
    
    func syncWithBackend() { syncManager.syncWithBackend() }
    
    func logout() { profileManager.logout() }
    
    func saveProfile() { profileManager.saveProfile() }
    
    @discardableResult
    func initiatePayment(merchantName: String, amount: String, categoryName: String, url: String, app: String) -> String {
        transactionManager.initiatePayment(merchantName: merchantName, amount: amount, categoryName: categoryName, url: url, app: app)
    }
    
    func confirmTransaction(_ id: String, finalAmount: Double? = nil) {
        transactionManager.confirmTransaction(id, finalAmount: finalAmount)
    }
    
    func rejectTransaction(_ id: String) {
        transactionManager.rejectTransaction(id)
    }
    
    func deleteTransaction(_ id: String) {
        transactionManager.deleteTransaction(id)
    }
    
    func addManualTransaction(merchantName: String, amount: String, categoryName: String, date: Date) {
        transactionManager.addManualTransaction(merchantName: merchantName, amount: amount, categoryName: categoryName, date: date)
    }
    
    func addCategory(name: String, icon: String) {
        categoryManager.addCategory(name: name, icon: icon)
    }
    
    func deleteCategory(at offsets: IndexSet) {
        categoryManager.deleteCategory(at: offsets)
    }
    
    func deleteCategory(id: Int?, replacementCategoryName: String? = nil) {
        categoryManager.deleteCategory(id: id, replacementCategoryName: replacementCategoryName)
    }
    
    func updateTransactionCategory(id: String, newCategoryName: String) {
        categoryManager.updateTransactionCategory(id: id, newCategoryName: newCategoryName)
    }
    
    func countTransactions(for categoryName: String) -> Int {
        categoryManager.countTransactions(for: categoryName)
    }
    
    func addRecurringTransaction(merchantName: String, amount: String, categoryName: String, frequency: RecurrenceFrequency, startDate: Date) {
        syncManager.addRecurringTransaction(merchantName: merchantName, amount: amount, categoryName: categoryName, frequency: frequency, startDate: startDate)
    }
    
    func deleteRecurringTransaction(id: String) {
        syncManager.deleteRecurringTransaction(id: id)
    }
    
    func categorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        analyticsManager.categorySpending(for: period)
    }
    
    func groupedCategorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        analyticsManager.groupedCategorySpending(for: period)
    }
    
    func parseUPI(url: String, key: String) -> String? { upiParser.parseUPI(url: url, key: key) }
    func validateQR(url: String) -> QRType { upiParser.validateQR(url: url) }
    func getBestPayeeName(from url: String) -> String { upiParser.getBestPayeeName(from: url) }
}
