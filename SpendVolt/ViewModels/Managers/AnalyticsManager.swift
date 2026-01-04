import Foundation

class AnalyticsManager {
    private let state: AppState
    private let analyticsEngine: AnalyticsEngineProtocol

    init(state: AppState, analyticsEngine: AnalyticsEngineProtocol) {
        self.state = state
        self.analyticsEngine = analyticsEngine
    }

    func categorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        analyticsEngine.calculateCategorySpending(transactions: state.transactions, categories: state.categories, period: period)
    }

    func groupedCategorySpending(for period: AnalysisPeriod) -> [CategorySpending] {
        let allSpending = categorySpending(for: period)
        if allSpending.count <= 5 { return allSpending }
        
        let topFive = Array(allSpending.prefix(5))
        let remaining = allSpending.dropFirst(5)
        
        let othersTotal = remaining.reduce(0) { $0 + $1.totalAmount }
        let othersPercentage = remaining.reduce(0) { $0 + $1.percentage }
        
        let others = CategorySpending(
            categoryName: "Others",
            totalAmount: othersTotal,
            percentage: othersPercentage,
            icon: "ellipsis.circle.fill"
        )
        
        var finalResult = topFive
        finalResult.append(others)
        return finalResult
    }
}

