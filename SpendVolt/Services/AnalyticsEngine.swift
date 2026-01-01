import Foundation

protocol AnalyticsEngineProtocol {
    func calculateTotalSpent(transactions: [Transaction], month: Int, year: Int) -> Double
    func calculateTopSpends(transactions: [Transaction], month: Int, year: Int, limit: Int) -> [Transaction]
    func calculateDailyInsight(totalSpent: Double, budget: Double) -> DailyInsight
    func calculateCategorySpending(transactions: [Transaction], categories: [UserCategory], period: AppViewModel.AnalysisPeriod) -> [CategorySpending]
}

class AnalyticsEngine: AnalyticsEngineProtocol {
    func calculateTotalSpent(transactions: [Transaction], month: Int, year: Int) -> Double {
        return transactions
            .filter { $0.status == .success }
            .filter {
                let m = Calendar.current.component(.month, from: $0.date)
                let y = Calendar.current.component(.year, from: $0.date)
                return m == month && y == year
            }
            .compactMap { Double($0.amount) }
            .reduce(0, +)
    }
    
    func calculateTopSpends(transactions: [Transaction], month: Int, year: Int, limit: Int) -> [Transaction] {
        return transactions
            .filter { $0.status == .success }
            .filter {
                let m = Calendar.current.component(.month, from: $0.date)
                let y = Calendar.current.component(.year, from: $0.date)
                return m == month && y == year
            }
            .sorted { (Double($0.amount) ?? 0) > (Double($1.amount) ?? 0) }
            .prefix(limit)
            .map { $0 }
    }
    
    func calculateDailyInsight(totalSpent: Double, budget: Double) -> DailyInsight {
        let calendar = Calendar.current
        let now = Date()
        
        guard let range = calendar.range(of: .day, in: .month, for: now) else {
            return DailyInsight(allowance: 0, isOverPace: false, paceDifference: 0)
        }
        
        let totalDays = range.count
        let currentDay = calendar.component(.day, from: now)
        let daysRemaining = max(1, totalDays - currentDay + 1)
        
        let dailyBudget = budget / Double(totalDays)
        let currentAverage = totalSpent / Double(max(1, currentDay))
        
        let allowance = max(0, (budget - totalSpent) / Double(daysRemaining))
        let isOverPace = currentAverage > dailyBudget
        let paceDifference = abs(currentAverage - dailyBudget)
        
        return DailyInsight(allowance: allowance, isOverPace: isOverPace, paceDifference: paceDifference)
    }
    
    func calculateCategorySpending(transactions: [Transaction], categories: [UserCategory], period: AppViewModel.AnalysisPeriod) -> [CategorySpending] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let periodTransactions = transactions
            .filter { $0.status == .success }
            .filter { $0.date >= startDate && $0.date <= now }
        
        let total = periodTransactions.compactMap { Double($0.amount) }.reduce(0, +)
        guard total > 0 else { return [] }
        
        var grouping: [String: Double] = [:]
        for txn in periodTransactions {
            let amt = Double(txn.amount) ?? 0
            grouping[txn.categoryName, default: 0] += amt
        }
        
        return grouping.map { name, amount in
            let icon = categories.first(where: { $0.name == name })?.icon ?? "tag.fill"
            return CategorySpending(
                categoryName: name,
                totalAmount: amount,
                percentage: (amount / total) * 100,
                icon: icon
            )
        }.sorted { $0.totalAmount > $1.totalAmount }
    }
}

