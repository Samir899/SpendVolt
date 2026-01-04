import Foundation
import Combine

class TransactionManager {
    private let state: AppState
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private var idMap: [String: String] = [:]
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
                               categoryName: categoryName)
        
        state.transactions.insert(newTxn, at: 0)
        
        networkService.createTransaction(newTxn)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.state.transactions.removeAll(where: { $0.id == tempId })
                }
            } receiveValue: { [weak self] dashboard in
                self?.onDashboardReceived?(dashboard)
            }
            .store(in: &cancellables)

        paymentService.openDirectApp(url: url, amount: amount, app: app)
        return tempId
    }

    func confirmTransaction(_ id: String, finalAmount: Double? = nil) {
        let currentId = idMap[id] ?? id
        if let index = state.transactions.firstIndex(where: { $0.id == currentId }) {
            let amountToSave = finalAmount ?? state.transactions[index].amount
            
            guard amountToSave > 0 else {
                state.errorMessage = "Transaction amount must be greater than zero."
                return
            }
            
            state.transactions[index].amount = amountToSave
            state.transactions[index].status = .success
            storageService.saveTransactions(state.transactions)
            
            if let intId = Int(currentId) {
                networkService.updateTransactionStatus(id: intId, status: AppConstants.TransactionStatus.success.rawValue)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                        self?.onDashboardReceived?(dashboard)
                    })
                    .store(in: &cancellables)
            }
        }
    }

    func rejectTransaction(_ id: String) {
        let currentId = idMap[id] ?? id
        if let index = state.transactions.firstIndex(where: { $0.id == currentId }) {
            state.transactions[index].status = .failure
            storageService.saveTransactions(state.transactions)
            
            if let intId = Int(currentId) {
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
        let currentId = idMap[id] ?? id
        state.transactions.removeAll(where: { $0.id == id || $0.id == currentId })
        storageService.saveTransactions(state.transactions)
        
        if let intId = Int(currentId) {
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
        
        let newTxn = Transaction(id: tempId, merchantName: merchantName, amount: doubleAmount, date: date, status: .success, categoryName: categoryName)
        state.transactions.insert(newTxn, at: 0)
        
        networkService.createTransaction(newTxn)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.state.transactions.removeAll(where: { $0.id == tempId })
                }
            } receiveValue: { [weak self] dashboard in
                self?.onDashboardReceived?(dashboard)
            }
            .store(in: &cancellables)
    }
}

