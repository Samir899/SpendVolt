import SwiftUI

struct HomeSummaryCard: View {
    let spent: Double
    let budget: Double
    let threshold: Double
    let insight: DailyInsight
    
    enum BudgetStatus {
        case safe, warning, danger
        
        var gradientColors: [Color] {
            switch self {
            case .safe: return [Theme.primary, Theme.primaryLight]
            case .warning: return [Color(hex: "F59E0B"), Color(hex: "FBBF24")]
            case .danger: return [Color(hex: "EF4444"), Color(hex: "F87171")]
            }
        }
        
        var icon: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.octagon.fill"
            }
        }
        
        var message: String {
            switch self {
            case .safe: return "On Track"
            case .warning: return "Near Limit"
            case .danger: return "Over Budget"
            }
        }
    }
    
    var status: BudgetStatus {
        spent > budget ? .danger : (spent > threshold ? .warning : .safe)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(status.message)
                            .font(.system(size: 12, weight: .bold))
                            .textCase(.uppercase)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .cornerRadius(6)
                        
                        Text("Monthly Spent")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(Theme.formatCurrency(spent))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: status.icon)
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            
            // Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(.white)
                            .frame(width: min(CGFloat(spent / max(1, budget)) * geo.size.width, geo.size.width), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Budget: \(Theme.formatCurrency(budget))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int((spent / max(1, budget)) * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Daily Insight Section
            Divider()
                .background(.white.opacity(0.3))
                .padding(.vertical, 4)
            
            HStack(spacing: 8) {
                Image(systemName: insight.isOverPace ? "arrow.up.right.circle.fill" : "leaf.fill")
                    .foregroundColor(insight.isOverPace ? .white : .white.opacity(0.9))
                
                Text(insight.isOverPace ? 
                     "Spending \(Theme.formatCurrency(insight.paceDifference)) above daily pace" : 
                     "Safe to spend \(Theme.formatCurrency(insight.allowance)) today")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: status.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: status.gradientColors.first!.opacity(0.3), radius: 15, x: 0, y: 10)
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

