import Foundation

struct Transaction: Identifiable, Codable, Equatable {
    var id: String
    var merchantName: String
    var amount: Double
    var date: Date
    var status: AppConstants.TransactionStatus
    var categoryName: String = AppConstants.Category.other
    
    init(id: String = UUID().uuidString, 
         merchantName: String, 
         amount: Double, 
         date: Date, 
         status: AppConstants.TransactionStatus, 
         categoryName: String = AppConstants.Category.other) {
        self.id = id
        self.merchantName = merchantName
        self.amount = amount
        self.date = date
        self.status = status
        self.categoryName = categoryName
    }
}

