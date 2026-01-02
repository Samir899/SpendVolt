import Foundation

struct UserProfile: Codable {
    var name: String
    var currency: String
    var monthlyBudget: Double
    var energyType: EnergyType
    var defaultPaymentApp: String
    var budgetWarningThreshold: Double // 0.0 to 1.0
    var monthlyResetDay: Int // 1 to 31
    
    enum EnergyType: String, Codable, CaseIterable, Identifiable {
        case petrol = "Petrol"
        case diesel = "Diesel"
        case electric = "Electric (EV)"
        case gas = "Natural Gas"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .petrol, .diesel: return "fuelpump.fill"
            case .electric: return "bolt.car.fill"
            case .gas: return "flame.fill"
            }
        }
    }
    
    static let `default` = UserProfile(
        name: "User",
        currency: "INR",
        monthlyBudget: 10000,
        energyType: .petrol,
        defaultPaymentApp: "Google Pay",
        budgetWarningThreshold: 0.8,
        monthlyResetDay: 1
    )
}

