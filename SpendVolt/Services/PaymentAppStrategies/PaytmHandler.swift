import Foundation

struct PaytmHandler: PaymentAppHandler {
    let appName = "Paytm"
    func transform(upiString: String) -> String {
        upiString.replacingOccurrences(of: "upi://pay", with: "paytmmp://pay")
    }
}

