import SwiftUI

struct ScanActionCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(Theme.primary.opacity(0.05))
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Theme.primary)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                    Text("Scan to Pay")
                        .fontWeight(.bold)
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding(.vertical, 18)
                .padding(.horizontal, 44)
                .background(Theme.primary)
                .clipShape(Capsule())
                .shadow(color: Theme.primary.opacity(0.4), radius: 12, y: 8)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
