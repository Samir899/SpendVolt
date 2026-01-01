import Foundation

struct UserCategory: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var icon: String
    
    static let defaults = [
        UserCategory(name: "Fuel", icon: "fuelpump.fill"),
        UserCategory(name: "Grocery", icon: "cart.fill"),
        UserCategory(name: "Rent", icon: "house.fill"),
        UserCategory(name: "Electricity", icon: "bolt.fill"),
        UserCategory(name: "Dining", icon: "fork.knife"),
        UserCategory(name: "Other", icon: "bag.fill")
    ]
}

