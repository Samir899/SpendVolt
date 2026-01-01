import Foundation
import SwiftUI

protocol TransactionStorage {
    func saveTransactions(_ transactions: [Transaction])
    func loadTransactions() -> [Transaction]
}

protocol CategoryStorage {
    func saveCategories(_ categories: [UserCategory])
    func loadCategories() -> [UserCategory]
}

protocol ProfileStorage {
    func saveProfile(_ profile: UserProfile)
    func loadProfile() -> UserProfile
}

protocol StorageServiceProtocol: TransactionStorage, CategoryStorage, ProfileStorage {}

class StorageService: StorageServiceProtocol {
    private let transactionsKey = "saved_transactions"
    private let categoriesKey = "user_categories"
    private let profileKey = "user_profile"
    
    // ... existing saveTransactions/loadTransactions ...
    
    func saveTransactions(_ transactions: [Transaction]) {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
    
    func loadTransactions() -> [Transaction] {
        guard let data = UserDefaults.standard.data(forKey: transactionsKey),
              let decoded = try? JSONDecoder().decode([Transaction].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // ... existing saveCategories/loadCategories ...
    
    func saveCategories(_ categories: [UserCategory]) {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
        }
    }
    
    func loadCategories() -> [UserCategory] {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey),
              let decoded = try? JSONDecoder().decode([UserCategory].self, from: data) else {
            return UserCategory.defaults
        }
        return decoded
    }

    // MARK: - Profile Storage
    
    func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func loadProfile() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile.default
        }
        return decoded
    }
}

