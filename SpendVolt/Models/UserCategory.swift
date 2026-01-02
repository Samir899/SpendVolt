import Foundation

struct UserCategory: Identifiable, Codable, Equatable {
    var id: Int?
    var name: String
    var icon: String
    var type: String = "EXPENSE"
    
    static let defaults = [
        UserCategory(id: 1, name: "Fuel", icon: "fuelpump.fill", type: "EXPENSE"),
        UserCategory(id: 2, name: "Grocery", icon: "cart.fill", type: "EXPENSE"),
        UserCategory(id: 3, name: "Rent", icon: "house.fill", type: "EXPENSE"),
        UserCategory(id: 4, name: "Electricity", icon: "bolt.fill", type: "EXPENSE"),
        UserCategory(id: 5, name: "Dining", icon: "fork.knife", type: "EXPENSE"),
        UserCategory(id: 6, name: "Other", icon: "bag.fill", type: "EXPENSE")
    ]
}

