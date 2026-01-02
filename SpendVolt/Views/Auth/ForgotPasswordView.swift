import SwiftUI
import Combine

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.primary)
                        .padding(.bottom, 8)
                    
                    Text("Forgot Password?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 16) {
                    CustomAuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email Address",
                        text: $email,
                        textContentType: .emailAddress
                    )
                    .focused($isFocused)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    if let error = errorMessage {
                        ErrorBanner(message: error)
                    }
                    
                    if let success = successMessage {
                        SuccessBanner(message: success)
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: handleForgotPassword) {
                    HStack {
                        if isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link").font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: [Theme.primary, Theme.primaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Theme.primary.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(isLoading || email.isEmpty || !isValidEmail(email))
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func handleForgotPassword() {
        isFocused = false
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let authService = AuthService()
        authService.forgotPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { message in
                successMessage = message
                // Auto-dismiss after 3 seconds on success
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
            .store(in: &cancellables)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct SuccessBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.green)
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ForgotPasswordView()
}

