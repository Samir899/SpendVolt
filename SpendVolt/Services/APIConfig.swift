import Foundation

struct APIConfig {
    // Simply change this IP once when your network changes
    static let serverIP = "192.168.1.6"
    
    static var spendVoltBaseURL: String {
        return "http://\(serverIP):8081/api"
    }
    
    static var oauthBaseURL: String {
        return "http://\(serverIP):9000/api"
    }
}

