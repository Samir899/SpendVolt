import SwiftUI

struct ManualExpenseSheet: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var merchantName: String = ""
    @State private var amount: String = ""
    @State private var selectedCategoryName: String = "Other"
    @State private var date: Date = Date()
    @State private var isRecurring: Bool = false
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Amount Input Hero
                        VStack(spacing: 12) {
                            Text("Enter Amount")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            HStack {
                                Text(viewModel.currencySymbol)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                TextField("0", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.primary)
                            }
                            .padding(.vertical, 30)
                            .frame(maxWidth: .infinity)
                            .background(Theme.secondaryBackground)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, Theme.horizontalPadding)
                        .padding(.top, 20)
                        
                        if !amount.isEmpty && (Double(amount) ?? 0) <= 0 {
                            Text("Amount must be greater than zero")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.top, -20)
                        }
                        
                        // Recurring Selection
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Make Recurring", systemImage: "arrow.2.squarepath")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Toggle("", isOn: $isRecurring)
                                    .tint(Theme.primary)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, Theme.horizontalPadding)
                            
                            if isRecurring {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(RecurrenceFrequency.allCases) { freq in
                                            Button {
                                                selectedFrequency = freq
                                            } label: {
                                                Text(freq.displayName)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(selectedFrequency == freq ? Theme.primary : Theme.secondaryBackground)
                                                    .foregroundColor(selectedFrequency == freq ? .white : Theme.textPrimary)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, Theme.horizontalPadding)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        // Details Card
                        VStack(spacing: 24) {
                            // Merchant/Title Input
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What for? (Cash, EMI, etc.)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                
                                TextField("e.g. Home Rent, Cash Payment, EMI", text: $merchantName)
                                    .padding(16)
                                    .background(Theme.secondaryBackground)
                                    .cornerRadius(16)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            // Date Picker Card
                            VStack(alignment: .leading, spacing: 10) {
                                Text(isRecurring ? "Start Date" : "Transaction Date")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textSecondary)
                                
                                if isRecurring {
                                    DatePicker("", selection: $date, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .tint(Theme.primary)
                                        .padding(12)
                                        .background(Theme.secondaryBackground)
                                        .cornerRadius(16)
                                } else {
                                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .tint(Theme.primary)
                                        .padding(12)
                                        .background(Theme.secondaryBackground)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.horizontalPadding)
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Category")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
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
                        
                        // Save Button
                        Button(action: {
                            saveExpense()
                            dismiss()
                        }) {
                            Text("Log Expense")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(merchantName.isEmpty || amount.isEmpty || (Double(amount) ?? 0) <= 0 ? Color.gray.opacity(0.3) : Theme.primary)
                                .cornerRadius(18)
                                .shadow(color: Theme.primary.opacity(0.3), radius: 10, y: 5)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(merchantName.isEmpty || amount.isEmpty || (Double(amount) ?? 0) <= 0)
                        .padding(.horizontal, Theme.horizontalPadding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Log Cash or Auto-Pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onChange(of: isRecurring) { newValue in
            if newValue {
                // If switching to recurring, ensure date is not in the past
                if date < Calendar.current.startOfDay(for: Date()) {
                    date = Date()
                }
            } else {
                // If switching to manual, ensure date is not in the future
                if date > Date() {
                    date = Date()
                }
            }
        }
    }
    
    private func saveExpense() {
        if isRecurring {
            viewModel.addRecurringTransaction(
                merchantName: merchantName,
                amount: amount,
                categoryName: selectedCategoryName,
                frequency: selectedFrequency,
                startDate: date
            )
        } else {
            viewModel.addManualTransaction(
                merchantName: merchantName,
                amount: amount,
                categoryName: selectedCategoryName,
                date: date
            )
        }
    }
}
