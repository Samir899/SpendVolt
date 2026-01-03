import UIKit

protocol PaymentServiceProtocol {
    func openDirectApp(url: String, amount: String, app: String)
}

class UPIPaymentService: PaymentServiceProtocol {
    // Registry of supported payment apps
    // To add a new app, simply add its handler here
    private let handlers: [PaymentAppHandler] = [
        GooglePayHandler(),
        PhonePeHandler(),
        PaytmHandler()
    ]

    func openDirectApp(url: String, amount: String, app: String) {
        // 1. Extract VPA (UPI ID)
        let cleanedURL = url.removingPercentEncoding ?? url
        
        func extractVPA() -> String {
            // Try query param 'pa='
            if let range = cleanedURL.range(of: "(?i)pa=[^&;?]+", options: .regularExpression) {
                return cleanedURL[range].replacingOccurrences(of: "pa=", with: "", options: .caseInsensitive)
            }
            // Try path-based VPA: upi://pay/vpa@bank
            if let range = cleanedURL.range(of: "(?<=upi://pay/)[^?&;?]+", options: .regularExpression) {
                let vpa = String(cleanedURL[range])
                if vpa.contains("@") { return vpa }
            }
            // Fallback: search for anything with @
            let parts = cleanedURL.components(separatedBy: CharacterSet(charactersIn: "?&;=/"))
            return parts.first(where: { $0.contains("@") }) ?? ""
        }

        let pa = extractVPA()
        guard !pa.isEmpty else { return }

        // 2. Launch the selected app cleanly (no deep link intent to avoid blocks)
        let baseSchemes: [String: String] = [
            "Google Pay": "tez://",
            "PhonePe": "phonepe://",
            "Paytm": "paytmmp://"
        ]
        
        let scheme = baseSchemes[app] ?? "upi://"
        if let url = URL(string: scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
