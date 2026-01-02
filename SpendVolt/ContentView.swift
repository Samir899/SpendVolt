import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var initialDashboard: AppDashboard?

    init() {
        // ... existing init ...
    }

    var body: some View {
        ZStack {
            if sessionManager.isAuthenticated {
                // The heavy AppViewModel and all its data are ONLY created here
                MainAppView(initialDashboard: initialDashboard)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                // Login flow is isolated and lightweight
                LoginView(onLoginSuccess: { response in
                    self.initialDashboard = response.dashboard
                    withAnimation(.spring()) {
                        sessionManager.saveSession(token: response.accessToken, username: response.username)
                    }
                })
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
            }
        }
    }
}
