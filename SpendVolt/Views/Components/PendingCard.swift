import SwiftUI

struct PendingCard: View {
    let transaction: Transaction
    let currencySymbol: String
    let categories: [UserCategory]
    var onUpdateCategory: ((String) -> Void)? = nil
    let onConfirm: () -> Void
    let onDelete: () -> Void
    
    var icon: String {
        if transaction.categoryName == "Unassigned" {
            return "questionmark.circle.fill"
        }
        return categories.first(where: { $0.name == transaction.categoryName })?.icon ?? "tag.fill"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.merchantName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    if transaction.categoryName == "Unassigned" {
                        unassignedMenu
                    } else {
                        Text(transaction.categoryName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Text(Theme.formatCurrency(transaction.amount, symbol: currencySymbol))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            HStack(spacing: 12) {
                // Delete Button
                Button(action: {
                    onDelete()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Verify Button
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Verify")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
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
            HStack(spacing: 2) {
                Text("Select Category")
                Image(systemName: "chevron.down")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.primary)
        }
    }
}
