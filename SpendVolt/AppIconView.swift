import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "FF6B00"), Color(hex: "FF8E31")],
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    AppIconView()
        .frame(width: 300, height: 300)
}

