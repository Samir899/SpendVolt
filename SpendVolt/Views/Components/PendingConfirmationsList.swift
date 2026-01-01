import SwiftUI

struct PendingConfirmationsList: View {
    let transactions: [Transaction]
    let categories: [UserCategory]
    let onUpdateCategory: (UUID, String) -> Void
    let onConfirm: (Transaction) -> Void
    let onDelete: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Confirmations")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("\(transactions.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.primary.opacity(0.1))
                    .foregroundColor(Theme.primary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, Theme.horizontalPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(transactions) { txn in
                        PendingCard(
                            transaction: txn,
                            categories: categories,
                            onUpdateCategory: { newCategory in
                                onUpdateCategory(txn.id, newCategory)
                            },
                            onConfirm: { onConfirm(txn) },
                            onDelete: { onDelete(txn.id) }
                        )
                        .frame(width: 300)
                    }
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 10)
            }
        }
    }
}

