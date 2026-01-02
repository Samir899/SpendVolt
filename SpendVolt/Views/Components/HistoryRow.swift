import SwiftUI

struct HistoryRow: View {
    let transaction: Transaction
    let currencySymbol: String
    let categories: [UserCategory]
    var onUpdateCategory: ((String) -> Void)? = nil
    
    var icon: String {
        if transaction.categoryName == "Unassigned" {
            return "questionmark.circle.fill"
        }
        return categories.first(where: { $0.name == transaction.categoryName })?.icon ?? "tag.fill"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 6) {
                    if transaction.categoryName == "Unassigned" {
                        unassignedMenu
                    } else {
                        Text(transaction.categoryName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        
                        Text("•")
                            .foregroundColor(Theme.textTertiary)
                        
                        Text(transaction.date, style: .date)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(Theme.formatCurrency(transaction.amount, symbol: currencySymbol))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .strikethrough(transaction.status == .failure)
                    .foregroundColor(transaction.status == .failure ? Theme.textTertiary : Theme.textPrimary)
                
                if transaction.categoryName == "Unassigned" {
                    Text(transaction.date, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                } else {
                    statusBadge
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
    }
    
    private var statusColor: Color {
        if transaction.categoryName == "Unassigned" { return Theme.primary }
        switch transaction.status {
        case .success: return .green
        case .failure: return .red
        case .pending: return .blue
        }
    }
    
    private var statusBadge: some View {
        Text(transaction.status.rawValue.capitalized)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var unassignedMenu: some View {
        Menu {
            ForEach(categories) { category in
                Button {
                    onUpdateCategory?(category.name)
                } label: {
                    Label(category.name, systemImage: category.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Tap to Categorize")
                Image(systemName: "chevron.down")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.primary.opacity(0.1))
            .cornerRadius(6)
        }
    }
}
