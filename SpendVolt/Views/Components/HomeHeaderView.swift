import SwiftUI

struct HomeHeaderView: View {
    let userName: String
    let onProfileTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(userName)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Text("SpendVolt")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Theme.primary)
            }
            Spacer()
            
            Button(action: onProfileTap) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.primary)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, Theme.horizontalPadding)
        .padding(.top, 10)
    }
}

