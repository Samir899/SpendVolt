import SwiftUI

struct ProcessingOverlay: View {
    let transaction: Transaction
    let currencySymbol: String
    let onVerify: (Double) -> Void
    let onFail: () -> Void
    let onWait: () -> Void
    
    @State private var amountPaid: String
    
    init(transaction: Transaction, currencySymbol: String, onVerify: @escaping (Double) -> Void, onFail: @escaping () -> Void, onWait: @escaping () -> Void) {
        self.transaction = transaction
        self.currencySymbol = currencySymbol
        self.onVerify = onVerify
        self.onFail = onFail
        self.onWait = onWait
        
        // If the transaction already has a non-zero amount (from QR), we can show it, 
        // but per user request, we'll keep it empty if it's 0 or just always keep it empty for manual entry.
        if transaction.amount > 0 {
            _amountPaid = State(initialValue: String(format: "%.2f", transaction.amount))
        } else {
            _amountPaid = State(initialValue: "")
        }
    }
    
    var body: some View {
        ZStack {
            // Dark Blur Background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Status Header
                VStack(spacing: 8) {
                    Text("Verify Payment")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Did you finish paying at\n\(transaction.merchantName)?")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Theme.textSecondary)
                }
                
                // Editable Amount Box
                VStack(spacing: 12) {
                    Text("Final Amount Paid")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        Text(currencySymbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        TextField("0.00", text: $amountPaid)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Theme.secondaryBackground)
                    .cornerRadius(16)
                }
                .padding(.vertical, 8)
                
                VStack(spacing: 12) {
                    Button(action: {
                        let finalAmount = Double(amountPaid) ?? transaction.amount
                        onVerify(finalAmount)
                    }) {
                        Text("Confirm & Save")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.primary)
                            .cornerRadius(Theme.cornerRadius)
                            .shadow(color: Theme.primary.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onFail) {
                        Text("Payment Failed / Cancelled")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(Theme.cornerRadius)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onWait) {
                        Text("Verify Later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)
                }
            }
            .padding(24)
            .background(Theme.cardBackground)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 20)
            .padding(.horizontal, 30)
        }
    }
}
