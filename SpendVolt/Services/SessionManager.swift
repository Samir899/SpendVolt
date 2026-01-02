import Foundation
import Combine

protocol SessionManagerProtocol {
    var isAuthenticated: Bool { get }
    var currentUsername: String? { get }
    var authToken: String? { get }
    func saveSession(token: String, username: String)
    func clearSession()
}

class SessionManager: ObservableObject, SessionManagerProtocol {
    static let shared = SessionManager()
    
    @Published var isAuthenticated: Bool
    
    private let defaults = UserDefaults.standard
    
    init() {
        self.isAuthenticated = UserDefaults.standard.string(forKey: AppConstants.Storage.authToken) != nil
    }
    
    var currentUsername: String? {
        defaults.string(forKey: AppConstants.Storage.authUsername)
    }
    
    var authToken: String? {
        defaults.string(forKey: AppConstants.Storage.authToken)
    }
    
    func saveSession(token: String, username: String) {
        defaults.set(token, forKey: AppConstants.Storage.authToken)
        defaults.set(username, forKey: AppConstants.Storage.authUsername)
        isAuthenticated = true
    }
    
    func clearSession() {
        defaults.removeObject(forKey: AppConstants.Storage.authToken)
        defaults.removeObject(forKey: AppConstants.Storage.authUsername)
        isAuthenticated = false
    }
}

