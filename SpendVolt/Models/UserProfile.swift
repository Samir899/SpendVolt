import Foundation

struct UserProfile: Codable {
    var name: String
    var currency: Currency
    var monthlyBudget: Double
    var energyType: EnergyType
    var defaultPaymentApp: String
    var budgetWarningThreshold: Double // 0.0 to 1.0
    var monthlyResetDay: Int // 1 to 31
    
    enum Currency: String, Codable, CaseIterable, Identifiable {
        case INR = "₹"
        case USD = "$"
        case EUR = "€"
        case GBP = "£"
        
        var id: String { self.rawValue }
        var code: String { String(describing: self) }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let match = Currency.allCases.first(where: { $0.code == value || $0.rawValue == value }) {
                self = match
            } else {
                self = .INR
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.code)
        }
    }

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
        currency: .INR,
        monthlyBudget: 10000,
        energyType: .petrol,
        defaultPaymentApp: "Google Pay",
        budgetWarningThreshold: 0.8,
        monthlyResetDay: 1
    )
}

