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
        guard var components = URLComponents(string: url) else { return }
        var queryItems = components.queryItems ?? []
        
        queryItems.removeAll(where: { $0.name == "am" })
        
        if let amountDouble = Double(amount) {
            let formattedAmount = String(format: "%.2f", amountDouble)
            queryItems.append(URLQueryItem(name: "am", value: formattedAmount))
        }
        
        components.queryItems = queryItems
        components.scheme = "upi"
        components.host = "pay"
        
        guard let upiString = components.string else { return }
        
        let finalURLString = handlers
            .first(where: { $0.appName == app })?
            .transform(upiString: upiString) ?? upiString
        
        if let finalURL = URL(string: finalURLString) {
            UIApplication.shared.open(finalURL)
        }
    }
}
