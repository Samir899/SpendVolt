import SwiftUI

struct TopSpendsList: View {
    let topSpends: [Transaction]
    let categories: [UserCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Spends")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("This Month")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.horizontalPadding)
            
            VStack(spacing: 12) {
                ForEach(topSpends) { txn in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.primary.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: categories.first(where: { $0.name == txn.categoryName })?.icon ?? "tag.fill")
                                .foregroundColor(Theme.primary)
                                .font(.system(size: 16))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.merchantName)
                                .font(.system(size: 15, weight: .semibold))
                            Text(txn.categoryName)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(Theme.formatCurrency(Double(txn.amount) ?? 0))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding(12)
                    .background(Theme.secondaryBackground.opacity(0.5))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
        }
    }
}

