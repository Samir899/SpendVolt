import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case halfYearly = "HALF_YEARLY"
    case yearly = "YEARLY"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .halfYearly: return "Half Yearly"
        case .yearly: return "Yearly"
        }
    }
}

struct RecurringTransaction: Identifiable, Codable, Equatable {
    var id: String?
    let merchantName: String
    let amount: Double
    let categoryName: String
    let frequency: RecurrenceFrequency
    let nextDueDate: Date
    let isActive: Bool?
    
    init(id: String? = nil,
         merchantName: String,
         amount: Double,
         categoryName: String,
         frequency: RecurrenceFrequency,
         nextDueDate: Date,
         isActive: Bool? = true) {
        self.id = id
        self.merchantName = merchantName
        self.amount = amount
        self.categoryName = categoryName
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.isActive = isActive
    }
}

