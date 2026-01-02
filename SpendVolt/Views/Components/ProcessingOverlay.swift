import SwiftUI

struct ProcessingOverlay: View {
    let transaction: Transaction
    let onVerify: () -> Void
    let onFail: () -> Void
    let onWait: () -> Void
    
    var body: some View {
        ZStack {
            // Dark Blur Background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Animated Icon
                ZStack {
                    Circle()
                        .stroke(Theme.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Theme.primary)
                }
                
                    VStack(spacing: 12) {
                        Text("Verify Payment")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Did you finish paying \(Theme.formatCurrency(transaction.amount)) at \(transaction.merchantName)?")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 20)
                    }
                
                VStack(spacing: 16) {
                    Button(action: onVerify) {
                        Text("Yes, Paid Successfully")
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
                        Text("No, Payment Failed")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(Theme.cornerRadius)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: onWait) {
                        Text("I'll verify later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)
                }
            }
            .padding(32)
            .background(Theme.cardBackground)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 20)
            .padding(.horizontal, 30)
        }
    }
}
