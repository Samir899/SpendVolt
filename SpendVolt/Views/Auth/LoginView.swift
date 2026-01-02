import SwiftUI
import Combine

struct LoginView: View {
    let onLoginSuccess: (AuthResponse) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignup = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Focused management
    @FocusState private var focusedField: Field?
    enum Field { case username, password }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            // Simplified background without drawingGroup to prevent render-tree hangs
            Group {
                Circle()
                    .fill(Theme.primary.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: -350)
                
                Circle()
                    .fill(Theme.primary.opacity(0.03))
                    .frame(width: 200, height: 200)
                    .offset(x: -100, y: 300)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.primary)
                            .frame(width: 80, height: 80)
                            .shadow(color: Theme.primary.opacity(0.2), radius: 10, y: 5)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("SpendVolt")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Smart Expense Tracking")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .tracking(1.2)
                }
                .padding(.bottom, 40)
                
                // Form
                VStack(spacing: 16) {
                    CustomAuthTextField(
                        icon: "person.fill",
                        placeholder: "Username or Email",
                        text: $username,
                        textContentType: .username
                    )
                    .focused($focusedField, equals: .username)
                    
                    CustomAuthTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password
                    )
                    .focused($focusedField, equals: .password)
                    
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            focusedField = nil // Dismiss keyboard
                        }
                        .font(.footnote.bold())
                        .foregroundColor(Theme.primary)
                    }
                    .padding(.top, -8)
                }
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    ErrorBanner(message: error)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer(minLength: 30)
                
                // Action Buttons
                VStack(spacing: 20) {
                    Button(action: performLogin) {
                        HStack {
                            if isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In").font(.headline)
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
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(Theme.textSecondary)
                        Button("Join Now") {
                            focusedField = nil
                            showingSignup = true
                        }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        // Dismiss keyboard when tapping away using a safe method
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
        )
        .sheet(isPresented: $showingSignup) {
            SignupView(onSignupSuccess: {
                self.showingSignup = false
            })
        }
    }
    
    private func performLogin() {
        focusedField = nil // Dismiss keyboard
        isLoading = true
        errorMessage = nil
        
        let authService = AuthService()
        authService.login(username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                }
            } receiveValue: { response in
                onLoginSuccess(response)
            }
            .store(in: &cancellables)
    }
}
