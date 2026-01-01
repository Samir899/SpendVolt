import Foundation

struct CategorySpending: Identifiable {
    let id = UUID()
    let categoryName: String
    let totalAmount: Double
    let percentage: Double
    let icon: String
}

struct DailyInsight {
    let allowance: Double
    let isOverPace: Bool
    let paceDifference: Double
}

