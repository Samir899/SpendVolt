import Foundation
import Combine

class TransactionManager {
    private let state: AppState
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var onDashboardReceived: ((AppDashboard) -> Void)?

    init(state: AppState, 
         networkService: NetworkServiceProtocol, 
         storageService: StorageServiceProtocol,
         paymentService: PaymentServiceProtocol) {
        self.state = state
        self.networkService = networkService
        self.storageService = storageService
        self.paymentService = paymentService
        
        setupBindings()
    }

    private func setupBindings() {
        state.$transactions
            .map { $0.filter { $0.status == .pending } }
            .assign(to: &state.$pendingTransactions)
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
                               categoryName: categoryName,
                               note: tempId) // Store UUID in note for future sync matching
        
        // 1. Add to local state
        state.transactions.insert(newTxn, at: 0)
        
        // 2. Persist locally immediately so it survives app restarts
        storageService.saveTransactions(state.transactions)
        
        // 3. Open the payment app
        paymentService.openDirectApp(url: url, amount: amount, app: app)
        
        return tempId
    }

    func confirmTransaction(_ id: String, finalAmount: Double? = nil) {
        if let index = state.transactions.firstIndex(where: { $0.id == id }) {
            let amountToSave = finalAmount ?? state.transactions[index].amount
            
            guard amountToSave > 0 else {
                state.errorMessage = "Transaction amount must be greater than zero."
                return
            }
            
            // 1. Update local state
            state.transactions[index].amount = amountToSave
            state.transactions[index].status = .success
            storageService.saveTransactions(state.transactions)
            
            // 2. Send to backend now that it's confirmed
            let transactionToSync = state.transactions[index]
            networkService.createTransaction(transactionToSync)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        print("Failed to sync confirmed transaction: \(error)")
                    }
                } receiveValue: { [weak self] dashboard in
                    print("Transaction synced successfully with backend")
                    self?.onDashboardReceived?(dashboard)
                }
                .store(in: &cancellables)
        }
    }

    func rejectTransaction(_ id: String) {
        if let index = state.transactions.firstIndex(where: { $0.id == id }) {
            state.transactions[index].status = .failure
            storageService.saveTransactions(state.transactions)
            
            // If it was already on the backend (has an Int ID), update it there too
            if let intId = Int(id) {
                networkService.updateTransactionStatus(id: intId, status: AppConstants.TransactionStatus.failure.rawValue)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                        self?.onDashboardReceived?(dashboard)
                    })
                    .store(in: &cancellables)
            }
        }
    }

    func deleteTransaction(_ id: String) {
        state.transactions.removeAll(where: { $0.id == id })
        storageService.saveTransactions(state.transactions)
        
        if let intId = Int(id) {
            networkService.deleteTransaction(id: intId)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                    self?.onDashboardReceived?(dashboard)
                })
                .store(in: &cancellables)
        }
    }

    func addManualTransaction(merchantName: String, amount: String, categoryName: String, date: Date) {
        let tempId = UUID().uuidString
        let doubleAmount = Double(amount) ?? 0.0
        
        guard doubleAmount > 0 else {
            state.errorMessage = "Please enter an amount greater than zero."
            return
        }
        
        let newTxn = Transaction(id: tempId, 
                                merchantName: merchantName, 
                                amount: doubleAmount, 
                                date: date, 
                                status: .success, 
                                categoryName: categoryName)
        
        // 1. Update local state
        state.transactions.insert(newTxn, at: 0)
        storageService.saveTransactions(state.transactions)
        
        // 2. Sync with backend
        networkService.createTransaction(newTxn)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to sync manual transaction: \(error)")
                }
            } receiveValue: { [weak self] dashboard in
                self?.onDashboardReceived?(dashboard)
            }
            .store(in: &cancellables)
    }
}

