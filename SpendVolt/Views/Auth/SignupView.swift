import SwiftUI
import Combine

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    let onSignupSuccess: () -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var registrationResult: RegistrationResponse?
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            // Decorative elements
            Circle()
                .fill(Theme.primary.opacity(0.05))
                .frame(width: 250, height: 250)
                .offset(x: -120, y: -300)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Join SpendVolt")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Start tracking your expenses with ease")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                if let result = registrationResult {
                    successCard(result: result)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    registrationForm
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                Spacer()
                
                if registrationResult == nil {
                    // Back to Login
                    Button("Already have an account? Log In") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.primary)
                    .padding(.bottom, 20)
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: registrationResult == nil)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
    
    private var registrationForm: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                CustomAuthTextField(
                    icon: "person.fill",
                    placeholder: "First Name",
                    text: $firstName,
                    textContentType: .givenName
                )
                
                CustomAuthTextField(
                    icon: "person.2.fill",
                    placeholder: "Last Name",
                    text: $lastName,
                    textContentType: .familyName
                )
                
                CustomAuthTextField(
                    icon: "envelope.fill",
                    placeholder: "Email Address",
                    text: $email,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
            }
            .padding(.horizontal, 24)
            
            if let error = errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Button(action: performSignup) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Theme.primary, Theme.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Theme.primary.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isLoading || firstName.isEmpty || lastName.isEmpty || email.isEmpty)
            .padding(.horizontal, 24)
        }
    }
    
    private func successCard(result: RegistrationResponse) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to SpendVolt!")
                    .font(.title2.bold())
                    .foregroundColor(Theme.textPrimary)
                
                Text("Your account has been created successfully.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                InfoRow(label: "Username", value: result.username, icon: "person.text.rectangle")
                InfoRow(label: "Next Step", value: "Check your email for a temporary password.", icon: "envelope.badge")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.secondaryBackground)
            .cornerRadius(16)
            
            Button(action: {
                dismiss()
                onSignupSuccess()
            }) {
                Text("Sign In Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.primary)
                    .cornerRadius(16)
                    .shadow(color: Theme.primary.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(30)
        .background(Theme.cardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
    
    private func performSignup() {
        isLoading = true
        errorMessage = nil
        
        let authService = AuthService()
        authService.signup(firstName: firstName, lastName: lastName, email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { response in
                self.registrationResult = response
            }
            .store(in: &cancellables)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }
}
