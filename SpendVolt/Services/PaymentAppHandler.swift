import Foundation

protocol PaymentAppHandler {
    var appName: String { get }
    func transform(upiString: String) -> String
}

