import Foundation

struct UserCategory: Identifiable, Codable, Equatable {
    var id: Int?
    var name: String
    var icon: String
    
    static let defaults = [
        UserCategory(id: 1, name: "Fuel", icon: "fuelpump.fill"),
        UserCategory(id: 2, name: "Grocery", icon: "cart.fill"),
        UserCategory(id: 3, name: "Rent", icon: "house.fill"),
        UserCategory(id: 4, name: "Electricity", icon: "bolt.fill"),
        UserCategory(id: 5, name: "Dining", icon: "fork.knife"),
        UserCategory(id: 6, name: "Other", icon: "bag.fill")
    ]
}

