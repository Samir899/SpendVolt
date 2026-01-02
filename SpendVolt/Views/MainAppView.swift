import SwiftUI

struct MainAppView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var selectedTab = 0
    
    init(initialDashboard: AppDashboard? = nil) {
        _viewModel = StateObject(wrappedValue: AppViewModel(initialDashboard: initialDashboard))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("Expenses", systemImage: selectedTab == 1 ? "clock.arrow.circlepath" : "clock")
                }
                .tag(1)
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .accentColor(Theme.primary)
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

