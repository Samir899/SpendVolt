import Foundation

enum AppConstants {
    enum Storage {
        static let authToken = "auth_token"
        static let authUsername = "auth_username"
        static let transactions = "saved_transactions"
        static let categories = "user_categories"
        static let profile = "user_profile"
        static let recurringTransactions = "recurring_transactions"
    }
    
    enum TransactionStatus: String, Codable {
        case pending = "PENDING"
        case success = "SUCCESS"
        case failure = "FAILURE"
    }
    
    enum Category {
        static let unassigned = "Unassigned"
        static let other = "Other"
    }
}

