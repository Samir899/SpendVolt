import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var monthlyBudget: String = ""
    @State private var energyType: UserProfile.EnergyType = .petrol
    @State private var defaultPaymentApp: String = "Google Pay"
    @State private var warningThreshold: Double = 0.8
    @State private var resetDay: Int = 1
    
    let paymentApps = ["Google Pay", "PhonePe", "Paytm"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Theme.primary)
                            .frame(width: 24)
                        TextField("Your Name", text: $name)
                    }
                }
                
                Section("Financial Goals") {
                    HStack {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .foregroundColor(Theme.primary)
                            .frame(width: 24)
                        Text("Monthly Budget")
                        Spacer()
                        TextField("0", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Theme.primary)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Warning Threshold")
                            Spacer()
                            Text("\(Int(warningThreshold * 100))%")
                                .foregroundColor(Theme.primary)
                                .fontWeight(.semibold)
                        }
                        Slider(value: $warningThreshold, in: 0.5...1.0, step: 0.05)
                            .tint(Theme.primary)
                    }
                    
                    Picker("Monthly Reset Day", selection: $resetDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("Day \(day)").tag(day)
                        }
                    }
                }
                
                Section("Preferences") {
                    Picker("Energy Type", selection: $energyType) {
                        ForEach(UserProfile.EnergyType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    
                    Picker("Default Payment App", selection: $defaultPaymentApp) {
                        ForEach(paymentApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                    }
                }
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    private func loadProfileData() {
        name = viewModel.profile.name
        monthlyBudget = String(format: "%.0f", viewModel.profile.monthlyBudget)
        energyType = viewModel.profile.energyType
        defaultPaymentApp = viewModel.profile.defaultPaymentApp
        warningThreshold = viewModel.profile.budgetWarningThreshold
        resetDay = viewModel.profile.monthlyResetDay
    }
    
    private func saveProfile() {
        viewModel.profile.name = name
        viewModel.profile.monthlyBudget = Double(monthlyBudget) ?? 0
        viewModel.profile.energyType = energyType
        viewModel.profile.defaultPaymentApp = defaultPaymentApp
        viewModel.profile.budgetWarningThreshold = warningThreshold
        viewModel.profile.monthlyResetDay = resetDay
        viewModel.saveProfile()
    }
}

