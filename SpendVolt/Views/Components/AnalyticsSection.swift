import SwiftUI
import Charts

struct AnalyticsSection: View {
    @Binding var selectedPeriod: AnalysisPeriod
    let currencySymbol: String
    let fullSpendingData: [CategorySpending]
    let chartData: [CategorySpending]
    let categories: [UserCategory]
    
    var body: some View {
        VStack(spacing: 24) {
            // Period Selector
            Picker("Period", selection: $selectedPeriod) {
                ForEach(AnalysisPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            if fullSpendingData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textTertiary)
                    Text("No data for this \(selectedPeriod.rawValue.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Theme.secondaryBackground.opacity(0.5))
                .cornerRadius(16)
            } else {
                // Horizontal Bar Chart (Grouped Top 5 + Others)
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Amount", item.totalAmount),
                            y: .value("Category", item.categoryName)
                        )
                        .foregroundStyle(Theme.primary.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text(Theme.formatCurrency(item.totalAmount, symbol: currencySymbol))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                .frame(height: CGFloat(chartData.count) * 45) // Dynamic height based on number of bars
                .chartXAxis(.hidden) // Hide X axis for a cleaner look since we have annotations
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let name = value.as(String.self) {
                                HStack {
                                    Image(systemName: chartData.first(where: { $0.categoryName == name })?.icon ?? "tag.fill")
                                        .font(.system(size: 10))
                                    Text(name)
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                        }
                    }
                }
                
                // Ranked Categories (Full List)
                VStack(spacing: 12) {
                    ForEach(fullSpendingData) { item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primary.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.primary)
                            }
                            
                            Text(item.categoryName)
                                .font(.system(size: 14, weight: .medium))
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(Theme.formatCurrency(item.totalAmount, symbol: currencySymbol))
                                    .font(.system(size: 14, weight: .bold))
                                Text("\(Int(item.percentage))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.secondaryBackground.opacity(0.5))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.horizontalPadding)
    }
}

