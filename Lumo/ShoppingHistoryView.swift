//
//  ShoppingHistoryView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct ShoppingHistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTimeframe: Timeframe = .month
    @State private var selectedCategory: String? = nil
    @State private var showingInsights = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var filteredHistory: [ShoppingHistory] {
        let calendar = Calendar.current
        let now = Date()
        
        return appState.shoppingHistory.filter { history in
            switch selectedTimeframe {
            case .week:
                return calendar.isDate(history.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(history.date, equalTo: now, toGranularity: .month)
            case .quarter:
                let quarterStart = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
                return history.date >= quarterStart
            case .year:
                return calendar.isDate(history.date, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Timeframe Selector
                        timeframeSection
                        
                        // Summary Cards
                        summarySection
                        
                        // Spending Chart
                        spendingChartSection
                        
                        // Store Analysis
                        storeAnalysisSection
                        
                        // Category Breakdown
                        categoryBreakdownSection
                        
                        // Recent Trips
                        recentTripsSection
                        
                        // Insights
                        insightsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Shopping History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Insights") {
                        showingInsights = true
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .sheet(isPresented: $showingInsights) {
            ShoppingInsightsView(history: filteredHistory)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shopping History")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Track your spending patterns and discover insights to save money.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Timeframe Section
    private var timeframeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeframe")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    TimeframeButton(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        selectedTimeframe = timeframe
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SummaryCard(
                    title: "Total Spent",
                    value: String(format: "$%.2f", totalSpent),
                    icon: "dollarsign.circle",
                    color: .lumoGreen
                )
                
                SummaryCard(
                    title: "Trips",
                    value: "\(filteredHistory.count)",
                    icon: "cart",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Average Trip",
                    value: String(format: "$%.2f", averageTripCost),
                    icon: "chart.bar",
                    color: .orange
                )
                
                SummaryCard(
                    title: "Items Bought",
                    value: "\(totalItems)",
                    icon: "bag",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Spending Chart Section
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            SpendingChartView(history: filteredHistory)
                .frame(height: 200)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
        }
    }
    
    // MARK: - Store Analysis Section
    private var storeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Store Analysis")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let storeStats = getStoreStatistics()
            
            VStack(spacing: 12) {
                ForEach(storeStats.prefix(3), id: \.store) { stat in
                    StoreStatRow(stat: stat)
                }
            }
        }
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let categoryStats = getCategoryStatistics()
            
            VStack(spacing: 12) {
                ForEach(categoryStats.prefix(5), id: \.category) { stat in
                    CategoryStatRow(stat: stat)
                }
            }
        }
    }
    
    // MARK: - Recent Trips Section
    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Trips")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full history
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            VStack(spacing: 12) {
                ForEach(filteredHistory.prefix(3), id: \.id) { trip in
                    RecentTripCard(trip: trip)
                }
            }
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Insights")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let insights = ShoppingInsights.generateInsights(from: filteredHistory)
            
            if insights.isEmpty {
                Text("No insights available for this timeframe")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.prefix(2), id: \.title) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalSpent: Double {
        filteredHistory.reduce(0) { $0 + $1.totalSpent }
    }
    
    private var averageTripCost: Double {
        filteredHistory.isEmpty ? 0 : totalSpent / Double(filteredHistory.count)
    }
    
    private var totalItems: Int {
        filteredHistory.reduce(0) { $0 + $1.items.count }
    }
    
    // MARK: - Helper Methods
    private func getStoreStatistics() -> [StoreStat] {
        let storeGroups = Dictionary(grouping: filteredHistory) { $0.store }
        return storeGroups.map { store, trips in
            StoreStat(
                store: store,
                trips: trips.count,
                totalSpent: trips.reduce(0) { $0 + $1.totalSpent },
                averageSpent: trips.reduce(0) { $0 + $1.totalSpent } / Double(trips.count)
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private func getCategoryStatistics() -> [CategoryStat] {
        let categoryGroups = Dictionary(grouping: filteredHistory) { $0.category }
        return categoryGroups.map { category, trips in
            CategoryStat(
                category: category,
                trips: trips.count,
                totalSpent: trips.reduce(0) { $0 + $1.totalSpent },
                itemCount: trips.reduce(0) { $0 + $1.items.count }
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
}

// MARK: - Timeframe Button
struct TimeframeButton: View {
    let timeframe: ShoppingHistoryView.Timeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Spending Chart View
struct SpendingChartView: View {
    let history: [ShoppingHistory]
    
    var body: some View {
        // Simple bar chart representation
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(history.suffix(7), id: \.id) { trip in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.lumoGreen)
                        .frame(height: max(20, CGFloat(trip.totalSpent / 10)))
                    
                    Text(String(format: "$%.0f", trip.totalSpent))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Store Stat
struct StoreStat {
    let store: String
    let trips: Int
    let totalSpent: Double
    let averageSpent: Double
}

// MARK: - Store Stat Row
struct StoreStatRow: View {
    let stat: StoreStat
    
    var body: some View {
        HStack(spacing: 12) {
            // Store Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.store)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(stat.trips) trips")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", stat.totalSpent))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
                
                Text("Avg: " + String(format: "$%.2f", stat.averageSpent))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Category Stat
struct CategoryStat {
    let category: String
    let trips: Int
    let totalSpent: Double
    let itemCount: Int
}

// MARK: - Category Stat Row
struct CategoryStatRow: View {
    let stat: CategoryStat
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "tag")
                    .foregroundColor(.purple)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.category)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(stat.itemCount) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", stat.totalSpent))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
                
                Text("\(stat.trips) trips")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Recent Trip Card
struct RecentTripCard: View {
    let trip: ShoppingHistory
    
    var body: some View {
        HStack(spacing: 12) {
            // Trip Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "cart")
                    .foregroundColor(.orange)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.store)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(trip.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(trip.items.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", trip.totalSpent))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
                
                Text(trip.category)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: ShoppingInsights
    
    var body: some View {
        HStack(spacing: 12) {
            // Insight Icon
            ZStack {
                Circle()
                    .fill(insightColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: insightIcon)
                    .foregroundColor(insightColor)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var insightColor: Color {
        switch insight.type {
        case "Budget": return .red
        case "Savings": return .green
        case "Reminder": return .blue
        default: return .lumoGreen
        }
    }
    
    private var insightIcon: String {
        switch insight.type {
        case "Budget": return "exclamationmark.triangle"
        case "Savings": return "dollarsign.circle"
        case "Reminder": return "bell"
        default: return "lightbulb"
        }
    }
}

// MARK: - Shopping Insights View
struct ShoppingInsightsView: View {
    let history: [ShoppingHistory]
    @Environment(\.dismiss) private var dismiss
    
    var insights: [ShoppingInsights] {
        ShoppingInsights.generateInsights(from: history)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Smart Insights")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("AI-powered recommendations to help you save money and shop smarter.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        // Insights List
                        if insights.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.lumoGreen)
                                
                                Text("No Insights Available")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Keep shopping to generate personalized insights!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(insights, id: \.title) { insight in
                                    DetailedInsightCard(insight: insight)
                                }
                            }
                            .padding()
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
    }
}

// MARK: - Detailed Insight Card
struct DetailedInsightCard: View {
    let insight: ShoppingInsights
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(insightColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: insightIcon)
                        .foregroundColor(insightColor)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(insight.type)
                        .font(.caption)
                        .foregroundColor(insightColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(insightColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(nil)
            
            // Action Button
            Button("Learn More") {
                // TODO: Implement detailed insight view
            }
            .font(.caption)
            .foregroundColor(.lumoGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.lumoGreen.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var insightColor: Color {
        switch insight.type {
        case "Budget": return .red
        case "Savings": return .green
        case "Reminder": return .blue
        default: return .lumoGreen
        }
    }
    
    private var insightIcon: String {
        switch insight.type {
        case "Budget": return "exclamationmark.triangle"
        case "Savings": return "dollarsign.circle"
        case "Reminder": return "bell"
        default: return "lightbulb"
        }
    }
} 