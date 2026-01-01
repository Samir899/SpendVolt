import Foundation

struct PhonePeHandler: PaymentAppHandler {
    let appName = "PhonePe"
    func transform(upiString: String) -> String {
        upiString.replacingOccurrences(of: "upi://pay", with: "phonepe://pay")
    }
}

