import Foundation
import Combine

class CategoryManager {
    private let state: AppState
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var onDashboardReceived: ((AppDashboard) -> Void)?

    init(state: AppState, 
         networkService: NetworkServiceProtocol, 
         storageService: StorageServiceProtocol) {
        self.state = state
        self.networkService = networkService
        self.storageService = storageService
    }

    func addCategory(name: String, icon: String) {
        let newCat = UserCategory(name: name, icon: icon, type: "EXPENSE")
        
        networkService.createCategory(newCat)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] dashboard in
                self?.onDashboardReceived?(dashboard)
            })
            .store(in: &cancellables)
    }

    func deleteCategory(at offsets: IndexSet) {
        for index in offsets {
            let category = state.categories[index]
            if let id = category.id {
                networkService.deleteCategory(id: id)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                        self?.onDashboardReceived?(dashboard)
                    })
                    .store(in: &cancellables)
            }
        }
    }

    func deleteCategory(id: Int?, replacementCategoryName: String? = nil) {
        guard let id = id else { return }
        if let _ = state.categories.first(where: { $0.id == id }) {
            networkService.deleteCategory(id: id)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                    self?.onDashboardReceived?(dashboard)
                })
                .store(in: &cancellables)
        }
    }

    func moveTransactions(from oldName: String, to newName: String) {
        var modified = false
        for i in 0..<state.transactions.count {
            if state.transactions[i].categoryName == oldName {
                state.transactions[i].categoryName = newName
                modified = true
            }
        }
        if modified {
            storageService.saveTransactions(state.transactions)
        }
    }

    func countTransactions(for categoryName: String) -> Int {
        state.transactions.filter { $0.categoryName == categoryName }.count
    }

    func updateTransactionCategory(id: String, newCategoryName: String) {
        if let index = state.transactions.firstIndex(where: { $0.id == id }) {
            state.transactions[index].categoryName = newCategoryName
            storageService.saveTransactions(state.transactions)
            
            if let intId = Int(id) {
                networkService.updateTransactionCategory(id: intId, categoryName: newCategoryName)
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] dashboard in
                        self?.onDashboardReceived?(dashboard)
                    })
                    .store(in: &cancellables)
            }
        }
    }
}

