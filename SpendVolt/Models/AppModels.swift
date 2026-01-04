import Foundation

struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let totalAmount: Double
    let percentage: Double
    let icon: String
}

struct DailyInsight: Codable {
    let allowance: Double
    let isOverPace: Bool
    let paceDifference: Double
}

struct BackendStats: Codable {
    let totalSpentThisMonth: Double
    let topThreeSpends: [Transaction]
    let dailyInsight: DailyInsight
}

struct AppDashboard: Codable {
    let transactions: [Transaction]
    let categories: [UserCategory]
    let profile: UserProfile
    let stats: BackendStats
    let recurringTransactions: [RecurringTransaction]
}

enum AnalysisPeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { self.rawValue }
}

