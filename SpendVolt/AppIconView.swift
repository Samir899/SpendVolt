import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "6366F1"), Color(hex: "818CF8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: -5) {
                // The "Volt" Bolt
                Image(systemName: "bolt.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 400)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // The "S" for Spend
                Text("S")
                    .font(.system(size: 250, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: -50)
            }
        }
        .frame(width: 1024, height: 1024) // App store icon size
        .clipShape(RoundedRectangle(cornerRadius: 200))
    }
}

#Preview {
    AppIconView()
        .frame(width: 300, height: 300)
}

