import Foundation

struct APIConfig {
    // GCP External IPs
    static let backendIP = "34.180.26.38"
    static let oauthIP = "35.244.47.31"
    
    static var spendVoltBaseURL: String {
        return "http://\(backendIP):8081/api"
    }
    
    static var oauthBaseURL: String {
        return "http://\(oauthIP):9000/api"
    }
}

