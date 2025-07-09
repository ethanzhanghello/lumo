//
//  NutritionAnalysisView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI
import Charts

struct NutritionAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var selectedWeekStart = Date()
    @State private var showingGoals = false
    
    private var weeklyNutrition: [Date: NutritionData] {
        mealManager.calculateNutritionForWeek(starting: selectedWeekStart)
    }
    
    private var averageNutrition: NutritionData {
        let allNutrition = Array(weeklyNutrition.values)
        guard !allNutrition.isEmpty else { return NutritionData() }
        
        let totalCalories = allNutrition.reduce(0) { $0 + $1.calories }
        let totalProtein = allNutrition.reduce(0) { $0 + $1.protein }
        let totalCarbs = allNutrition.reduce(0) { $0 + $1.carbs }
        let totalFat = allNutrition.reduce(0) { $0 + $1.fat }
        let totalFiber = allNutrition.reduce(0) { $0 + ($1.fiber ?? 0) }
        let totalSugar = allNutrition.reduce(0) { $0 + ($1.sugar ?? 0) }
        let totalSodium = allNutrition.reduce(0) { $0 + ($1.sodium ?? 0) }
        
        let count = Double(allNutrition.count)
        
        return NutritionData(
            calories: totalCalories / allNutrition.count,
            protein: totalProtein / count,
            carbs: totalCarbs / count,
            fat: totalFat / count,
            fiber: totalFiber / count,
            sugar: totalSugar / count,
            sodium: totalSodium / allNutrition.count
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Week Selector
                        weekSelectorSection
                        
                        // Summary Cards
                        summaryCardsSection
                        
                        // Daily Breakdown
                        dailyBreakdownSection
                        
                        // Macro Distribution
                        macroDistributionSection
                        
                        // Goals vs Actual
                        goalsComparisonSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Goals") {
                        showingGoals = true
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .sheet(isPresented: $showingGoals) {
            NutritionGoalsView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Track your daily and weekly nutritional intake to meet your health goals.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Week Selector Section
    private var weekSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Button("Previous") {
                    selectedWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: selectedWeekStart) ?? selectedWeekStart
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
                
                Spacer()
                
                Text(weekRangeText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Next") {
                    selectedWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: selectedWeekStart) ?? selectedWeekStart
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
            }
        }
    }
    
    private var weekRangeText: String {
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: selectedWeekStart)) - \(formatter.string(from: endDate))"
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Average")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NutritionCard(
                    title: "Calories",
                    value: "\(averageNutrition.calories)",
                    unit: "kcal",
                    color: .orange,
                    icon: "flame"
                )
                
                NutritionCard(
                    title: "Protein",
                    value: String(format: "%.1f", averageNutrition.protein),
                    unit: "g",
                    color: .blue,
                    icon: "dumbbell"
                )
                
                NutritionCard(
                    title: "Carbs",
                    value: String(format: "%.1f", averageNutrition.carbs),
                    unit: "g",
                    color: .green,
                    icon: "leaf"
                )
                
                NutritionCard(
                    title: "Fat",
                    value: String(format: "%.1f", averageNutrition.fat),
                    unit: "g",
                    color: .yellow,
                    icon: "drop"
                )
            }
        }
    }
    
    // MARK: - Daily Breakdown Section
    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(0..<7) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedWeekStart) ?? Date()
                    let nutrition = weeklyNutrition[date] ?? NutritionData()
                    let meals = mealManager.meals(for: date)
                    
                    DailyNutritionCard(
                        date: date,
                        nutrition: nutrition,
                        mealCount: meals.count
                    )
                }
            }
        }
    }
    
    // MARK: - Macro Distribution Section
    private var macroDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macro Distribution")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                MacroBar(
                    title: "Protein",
                    value: averageNutrition.protein,
                    total: averageNutrition.protein + averageNutrition.carbs + averageNutrition.fat,
                    color: .blue
                )
                
                MacroBar(
                    title: "Carbs",
                    value: averageNutrition.carbs,
                    total: averageNutrition.protein + averageNutrition.carbs + averageNutrition.fat,
                    color: .green
                )
                
                MacroBar(
                    title: "Fat",
                    value: averageNutrition.fat,
                    total: averageNutrition.protein + averageNutrition.carbs + averageNutrition.fat,
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Goals Comparison Section
    private var goalsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goals vs Actual")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                GoalComparisonRow(
                    title: "Calories",
                    actual: averageNutrition.calories,
                    goal: mealManager.nutritionGoals.calories,
                    unit: "kcal"
                )
                
                GoalComparisonRow(
                    title: "Protein",
                    actual: averageNutrition.protein,
                    goal: mealManager.nutritionGoals.protein,
                    unit: "g"
                )
                
                GoalComparisonRow(
                    title: "Carbs",
                    actual: averageNutrition.carbs,
                    goal: mealManager.nutritionGoals.carbs,
                    unit: "g"
                )
                
                GoalComparisonRow(
                    title: "Fat",
                    actual: averageNutrition.fat,
                    goal: mealManager.nutritionGoals.fat,
                    unit: "g"
                )
            }
        }
    }
}

// MARK: - Nutrition Card
struct NutritionCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Daily Nutrition Card
struct DailyNutritionCard: View {
    let date: Date
    let nutrition: NutritionData
    let mealCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(nutrition.calories) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(mealCount) meals")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private var progress: Double {
        // Calculate progress based on calories (assuming 2000 is 100%)
        return min(Double(nutrition.calories) / 2000.0, 1.0)
    }
    
    private var progressColor: Color {
        if progress >= 0.8 && progress <= 1.2 {
            return .green
        } else if progress < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Macro Bar
struct MacroBar: View {
    let title: String
    let value: Double
    let total: Double
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return value / total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Goal Comparison Row
struct GoalComparisonRow: View {
    let title: String
    let actual: Double
    let goal: Double
    let unit: String
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return actual / goal
    }
    
    private var statusColor: Color {
        if progress >= 0.9 && progress <= 1.1 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", actual)) \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("Goal: \(String(format: "%.1f", goal)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Nutrition Goals View
struct NutritionGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var goals: NutritionData
    
    init() {
        _goals = State(initialValue: MealPlanManager.shared.nutritionGoals)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Set Your Goals")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            NutritionGoalRow(
                                title: "Daily Calories",
                                value: $goals.calories,
                                unit: "kcal",
                                range: 1200...3000
                            )
                            
                            NutritionGoalRow(
                                title: "Protein",
                                value: $goals.protein,
                                unit: "g",
                                range: 50...200
                            )
                            
                            NutritionGoalRow(
                                title: "Carbs",
                                value: $goals.carbs,
                                unit: "g",
                                range: 100...400
                            )
                            
                            NutritionGoalRow(
                                title: "Fat",
                                value: $goals.fat,
                                unit: "g",
                                range: 30...100
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        mealManager.nutritionGoals = goals
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
    }
}

// MARK: - Nutrition Goal Row
struct NutritionGoalRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.lumoGreen)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(.lumoGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 