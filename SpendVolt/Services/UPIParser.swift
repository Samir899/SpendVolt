import Foundation

protocol UPIParserProtocol {
    func parseUPI(url: String, key: String) -> String?
    func getBestPayeeName(from url: String) -> String
}

class UPIParser: UPIParserProtocol {
    func parseUPI(url: String, key: String) -> String? {
        let cleanedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyPattern = key.lowercased()
        
        // 1. Regex search for key=value
        let pattern = "(?:[?&;=]|^)\(keyPattern)=([^&;?]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: cleanedUrl, options: [], range: NSRange(location: 0, length: cleanedUrl.utf16.count)) {
            if let range = Range(match.range(at: 1), in: cleanedUrl) {
                let value = String(cleanedUrl[range])
                return value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? value.replacingOccurrences(of: "+", with: " ")
            }
        }
        
        // 2. Fallback for UPI ID (pa)
        if keyPattern == "pa" {
            // Check for VPA in path: upi://pay/someone@bank
            if let vpaRange = cleanedUrl.range(of: "(?<=upi://pay/)[^?&;]+", options: .regularExpression) {
                let vpa = String(cleanedUrl[vpaRange])
                if vpa.contains("@") { return vpa }
            }
            
            // Check if the whole string is just a VPA
            if cleanedUrl.contains("@") && !cleanedUrl.contains("=") && !cleanedUrl.contains(":") {
                return cleanedUrl
            }
        }
        
        return nil
    }

    func getBestPayeeName(from url: String) -> String {
        let cleaned = url.removingPercentEncoding ?? url
        
        // 1. Try to find 'pn=' (Name) - Case Insensitive
        if let nameRange = cleaned.range(of: "(?i)pn=[^&;?]+", options: .regularExpression) {
            let name = cleaned[nameRange].replacingOccurrences(of: "pn=", with: "", options: [.caseInsensitive]).replacingOccurrences(of: "+", with: " ")
            if !name.isEmpty { return name }
        }
        
        // 2. Try to find 'pa=' (UPI ID) - Case Insensitive
        if let upiRange = cleaned.range(of: "(?i)pa=[^&;?]+", options: .regularExpression) {
            let upi = cleaned[upiRange].replacingOccurrences(of: "pa=", with: "", options: [.caseInsensitive])
            if !upi.isEmpty { return upi }
        }
        
        // 3. Just look for anything with an '@' (The Account)
        let parts = cleaned.components(separatedBy: CharacterSet(charactersIn: "?&;=/"))
        if let vpa = parts.first(where: { $0.contains("@") }) {
            return vpa
        }
        
        // 4. Raw fallback
        let fallback = cleaned.replacingOccurrences(of: "upi://pay", with: "", options: .caseInsensitive).trimmingCharacters(in: .punctuationCharacters)
        return fallback.isEmpty ? "Unknown Payee" : fallback
    }
}

