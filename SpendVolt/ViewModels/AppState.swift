import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var pendingTransactions: [Transaction] = []
    @Published var totalSpentThisMonth: Double = 0
    @Published var topThreeSpends: [Transaction] = []
    @Published var dailyInsight: DailyInsight = DailyInsight(allowance: 0, isOverPace: false, paceDifference: 0)
    @Published var categories: [UserCategory] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var profile: UserProfile
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String? {
        didSet {
            if errorMessage != nil {
                showErrorAlert = true
            }
        }
    }
    @Published var showErrorAlert = false

    init(profile: UserProfile) {
        self.profile = profile
    }
}

