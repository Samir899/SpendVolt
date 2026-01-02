import SwiftUI

enum Theme {
    // MARK: - Colors
    static let primary = Color(hex: "6366F1") // Electric Indigo
    static let primaryLight = Color(hex: "818CF8") // Light Indigo
    static let primaryDark = Color(hex: "4F46E5") // Deep Indigo
    
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    static let cardBackground = Color(UIColor.systemBackground)
    static let cardShadow = Color.black.opacity(0.08)
    
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.7)
    
    // MARK: - Layout
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 20
    static let horizontalPadding: CGFloat = 20
    
    // MARK: - Styles
    static func cardStyle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: cardShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - Formatters
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter
    }()

    static func formatCurrency(_ amount: Double, symbol: String) -> String {
        let numberString = currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return symbol + numberString
    }
}

// MARK: - Professional UI Components
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Custom Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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

