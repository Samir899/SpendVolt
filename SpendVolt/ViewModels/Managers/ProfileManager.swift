import Foundation
import Combine

class ProfileManager {
    private let state: AppState
    private let networkService: NetworkServiceProtocol
    private let storageService: StorageServiceProtocol
    private let sessionManager: SessionManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var onDashboardReceived: ((AppDashboard) -> Void)?

    init(state: AppState, 
         networkService: NetworkServiceProtocol, 
         storageService: StorageServiceProtocol,
         sessionManager: SessionManagerProtocol) {
        self.state = state
        self.networkService = networkService
        self.storageService = storageService
        self.sessionManager = sessionManager
    }

    func saveProfile() {
        storageService.saveProfile(state.profile)
        networkService.updateProfile(state.profile)
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

    func logout() {
        sessionManager.clearSession()
        state.isAuthenticated = false
        state.transactions = []
        state.categories = UserCategory.defaults
    }
}

