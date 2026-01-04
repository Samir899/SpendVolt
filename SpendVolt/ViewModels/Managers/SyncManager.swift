import Foundation
import Combine

class SyncManager {
    private let state: AppState
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(state: AppState, 
         networkService: NetworkServiceProtocol, 
         storageService: StorageServiceProtocol) {
        self.state = state
        self.networkService = networkService
        self.storageService = storageService
    }

    func syncWithBackend() {
        guard state.isAuthenticated else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        let startComponents = calendar.dateComponents([.year, .month], from: now)
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        var endComponents = DateComponents()
        endComponents.month = 1
        endComponents.second = -1
        guard let endDate = calendar.date(byAdding: endComponents, to: startDate) else { return }
        
        networkService.fetchDashboard(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
            
        fetchRecurringTransactions()
    }

    func refreshStats() {
        let calendar = Calendar.current
        let now = Date()
        let startComponents = calendar.dateComponents([.year, .month], from: now)
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        var endComponents = DateComponents()
        endComponents.month = 1
        endComponents.second = -1
        guard let endDate = calendar.date(byAdding: endComponents, to: startDate) else { return }

        networkService.fetchDashboard(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Dashboard refresh failed: \(error)")
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
    }

    func applyDashboard(_ dashboard: AppDashboard) {
        state.objectWillChange.send()
        
        if state.transactions != dashboard.transactions { state.transactions = dashboard.transactions }
        if state.categories != dashboard.categories { state.categories = dashboard.categories }
        state.profile = dashboard.profile
        state.totalSpentThisMonth = dashboard.stats.totalSpentThisMonth
        state.topThreeSpends = dashboard.stats.topThreeSpends
        state.dailyInsight = dashboard.stats.dailyInsight
        state.recurringTransactions = dashboard.recurringTransactions // Added this line
        state.isAuthenticated = true
        
        storageService.saveTransactions(state.transactions)
        storageService.saveCategories(state.categories)
        storageService.saveProfile(state.profile)
        storageService.saveRecurringTransactions(state.recurringTransactions) // Added this line
    }

    func fetchRecurringTransactions() {
        networkService.fetchRecurringTransactions()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to fetch recurring: \(error)")
                }
            } receiveValue: { [weak self] recurring in
                self?.state.recurringTransactions = recurring
            }
            .store(in: &cancellables)
    }

    func addRecurringTransaction(merchantName: String, amount: String, categoryName: String, frequency: RecurrenceFrequency, startDate: Date) {
        let doubleAmount = Double(amount) ?? 0.0
        
        guard doubleAmount > 0 else {
            state.errorMessage = "Please enter an amount greater than zero."
            return
        }
        
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
                    self?.state.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
    }

    func deleteRecurringTransaction(id: String) {
        networkService.deleteRecurringTransaction(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] dashboard in
                self?.applyDashboard(dashboard)
            }
            .store(in: &cancellables)
    }
}

