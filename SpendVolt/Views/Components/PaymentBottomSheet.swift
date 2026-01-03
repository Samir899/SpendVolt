import SwiftUI

struct PaymentBottomSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let scannedCode: String
    @Binding var amount: String
    @Binding var selectedCategoryName: String
    let onSelect: (String) -> Void
    
    @State private var showAllApps = false
    
    private var merchantName: String {
        viewModel.getBestPayeeName(from: scannedCode)
    }
    
    private var payeeUPI: String {
        viewModel.parseUPI(url: scannedCode, key: "pa") ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Merchant Info
                VStack(spacing: 12) {
                    Text("Paying to")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                    
                    VStack(spacing: 4) {
                        Text(merchantName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        if !payeeUPI.isEmpty && merchantName.lowercased() != payeeUPI.lowercased() {
                            Text(payeeUPI)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .padding(.top, 30)
                
                // MARK: - Category Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Category")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .padding(.horizontal, Theme.horizontalPadding)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.categories) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategoryName == category.name
                                ) {
                                    selectedCategoryName = category.name
                                }
                            }
                        }
                        .padding(.horizontal, Theme.horizontalPadding)
                    }
                }
                
                // MARK: - Payment Apps
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Select Payment App")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        let defaultApp = viewModel.profile.defaultPaymentApp
                        if !showAllApps && !defaultApp.isEmpty {
                            Button {
                                withAnimation(.spring()) {
                                    showAllApps = true
                                }
                            } label: {
                                Text("Pay with other")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
                    
                    VStack(spacing: 12) {
                        let defaultApp = viewModel.profile.defaultPaymentApp
                        if showAllApps || defaultApp.isEmpty {
                            PaymentAppRow(name: "Google Pay", icon: "tez", isDefault: defaultApp == "Google Pay") { onSelect("Google Pay") }
                            PaymentAppRow(name: "PhonePe", icon: "phonepe", isDefault: defaultApp == "PhonePe") { onSelect("PhonePe") }
                            PaymentAppRow(name: "Paytm", icon: "paytm", isDefault: defaultApp == "Paytm") { onSelect("Paytm") }
                        } else {
                            PaymentAppRow(name: defaultApp, icon: iconFor(app: defaultApp), isDefault: true) { onSelect(defaultApp) }
                        }
                    }
                    .padding(.horizontal, Theme.horizontalPadding)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Theme.background)
    }
    
    private func iconFor(app: String) -> String {
        switch app {
        case "Google Pay": return "tez"
        case "PhonePe": return "phonepe"
        case "Paytm": return "paytm"
        default: return ""
        }
    }
}

struct CategoryChip: View {
    let category: UserCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                Text(category.name)
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(minWidth: 85)
            .padding(.vertical, 16)
            .background(isSelected ? Theme.primary : Theme.secondaryBackground)
            .foregroundColor(isSelected ? .white : Theme.textPrimary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Theme.tertiaryBackground, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PaymentAppRow: View {
    let name: String
    let icon: String
    var isDefault: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Text(name.prefix(1))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    if isDefault {
                        Text("Preferred")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.primary)
                            .textCase(.uppercase)
                    }
                }
                
                Spacer()
                
                if isDefault {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.primary)
                        .padding(.trailing, 4)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(16)
            .background(isDefault ? Theme.primary.opacity(0.05) : Theme.secondaryBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDefault ? Theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
