import Foundation

struct GooglePayHandler: PaymentAppHandler {
    let appName = "Google Pay"
    func transform(upiString: String) -> String {
        upiString.replacingOccurrences(of: "upi://pay", with: "tez://upi/pay")
    }
}

