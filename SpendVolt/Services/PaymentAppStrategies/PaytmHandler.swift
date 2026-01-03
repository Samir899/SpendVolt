import Foundation

struct PaytmHandler: PaymentAppHandler {
    let appName = "Paytm"
    func transform(upiString: String) -> String {
        // Paytm supports paytmmp:// for deep linking
        upiString.replacingOccurrences(of: "upi://pay", with: "paytmmp://pay")
    }
}

