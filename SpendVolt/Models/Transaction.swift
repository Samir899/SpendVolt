import Foundation

struct Transaction: Identifiable, Codable, Equatable {
    var id = UUID()
    let merchantName: String
    let amount: String
    let date: Date
    var status: TransactionStatus
    var categoryName: String = "Other"
    
    enum TransactionStatus: String, Codable, Equatable {
        case pending, success, failure
    }
}

