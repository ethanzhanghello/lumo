//
//  DietaryGoalsView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct DietaryGoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddGoal = false
    @State private var selectedGoal: DietaryGoal?
    @State private var showingGoalDetail = false
    @State private var showingRecommendations = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Progress Overview
                        progressOverviewSection
                        
                        // Active Goals
                        activeGoalsSection
                        
                        // Daily Progress
                        dailyProgressSection
                        
                        // Recommendations
                        recommendationsSection
                        
                        // Nutrition Tips
                        nutritionTipsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dietary Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Goal") {
                        showingAddGoal = true
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddDietaryGoalView()
        }
        .sheet(isPresented: $showingGoalDetail) {
            if let goal = selectedGoal {
                GoalDetailView(goal: goal)
            }
        }
        .sheet(isPresented: $showingRecommendations) {
            DietaryRecommendationsView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dietary Goals")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Track your nutrition goals and get personalized recommendations.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(appState.dietaryGoals.prefix(4), id: \.id) { goal in
                    GoalProgressCard(goal: goal) {
                        selectedGoal = goal
                        showingGoalDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Active Goals Section
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(appState.dietaryGoals.filter { $0.isActive }.count) active")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 12) {
                ForEach(appState.dietaryGoals.filter { $0.isActive }, id: \.id) { goal in
                    ActiveGoalCard(goal: goal) {
                        selectedGoal = goal
                        showingGoalDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Progress Section
    private var dailyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Progress")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ForEach(appState.dietaryGoals.filter { $0.isActive }, id: \.id) { goal in
                    DailyProgressRow(goal: goal)
                }
            }
        }
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Smart Recommendations")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingRecommendations = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            let recommendations = getRecommendations()
            
            if recommendations.isEmpty {
                Text("Great job! You're on track with your goals.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations.prefix(2), id: \.title) { recommendation in
                        DietaryRecommendationCard(recommendation: recommendation)
                    }
                }
            }
        }
    }
    
    // MARK: - Nutrition Tips Section
    private var nutritionTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Tips")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(getNutritionTips(), id: \.title) { tip in
                    NutritionTipCard(tip: tip)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getRecommendations() -> [DietaryRecommendation] {
        var recommendations: [DietaryRecommendation] = []
        
        for goal in appState.dietaryGoals where goal.isActive {
            let progress = goal.current / goal.target
            
            if progress < 0.5 {
                recommendations.append(DietaryRecommendation(
                    title: "Boost Your \(goal.type.rawValue)",
                    message: "You're only \(Int(progress * 100))% to your \(goal.type.rawValue.lowercased()) goal. Try adding more \(goal.type.rawValue.lowercased())-rich foods to your diet.",
                    type: .boost,
                    goalType: goal.type
                ))
            } else if progress > 1.2 {
                recommendations.append(DietaryRecommendation(
                    title: "Reduce \(goal.type.rawValue) Intake",
                    message: "You're \(Int((progress - 1) * 100))% over your \(goal.type.rawValue.lowercased()) goal. Consider healthier alternatives.",
                    type: .reduce,
                    goalType: goal.type
                ))
            }
        }
        
        return recommendations
    }
    
    private func getNutritionTips() -> [NutritionTip] {
        return [
            NutritionTip(
                title: "Stay Hydrated",
                message: "Drink 8 glasses of water daily for optimal health and metabolism.",
                icon: "drop.fill",
                color: .blue
            ),
            NutritionTip(
                title: "Eat More Fiber",
                message: "Aim for 25-30g of fiber daily from fruits, vegetables, and whole grains.",
                icon: "leaf.fill",
                color: .green
            ),
            NutritionTip(
                title: "Balance Your Plate",
                message: "Fill half your plate with vegetables, a quarter with protein, and a quarter with whole grains.",
                icon: "circle.grid.2x2.fill",
                color: .orange
            )
        ]
    }
}

// MARK: - Goal Progress Card
struct GoalProgressCard: View {
    let goal: DietaryGoal
    let onTap: () -> Void
    
    var progress: Double {
        goal.current / goal.target
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(goal.unit)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(goal.type.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(Int(goal.current))/\(Int(goal.target))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Active Goal Card
struct ActiveGoalCard: View {
    let goal: DietaryGoal
    let onTap: () -> Void
    
    var progress: Double {
        goal.current / goal.target
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Goal Icon
                ZStack {
                    Circle()
                        .fill(goalTypeColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: goalTypeIcon)
                        .foregroundColor(goalTypeColor)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(Int(goal.current)) / \(Int(goal.target)) \(goal.unit)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor)
                    
                    // Progress Bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(progressColor)
                                .frame(width: 60 * min(progress, 1.0), height: 4),
                            alignment: .leading
                        )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var goalTypeColor: Color {
        switch goal.type {
        case .calories: return .orange
        case .protein: return .blue
        case .carbs: return .green
        case .fat: return .yellow
        case .fiber: return .purple
        case .sugar: return .pink
        case .sodium: return .red
        }
    }
    
    private var goalTypeIcon: String {
        switch goal.type {
        case .calories: return "flame"
        case .protein: return "dumbbell"
        case .carbs: return "leaf"
        case .fat: return "drop"
        case .fiber: return "leaf.fill"
        case .sugar: return "heart"
        case .sodium: return "drop.fill"
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Daily Progress Row
struct DailyProgressRow: View {
    let goal: DietaryGoal
    
    var progress: Double {
        goal.current / goal.target
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Goal Icon
            ZStack {
                Circle()
                    .fill(goalTypeColor.opacity(0.2))
                    .frame(width: 30, height: 30)
                
                Image(systemName: goalTypeIcon)
                    .foregroundColor(goalTypeColor)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(Int(goal.current)) / \(Int(goal.target)) \(goal.unit)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Progress Bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor)
                            .frame(width: 80 * min(progress, 1.0), height: 6),
                        alignment: .leading
                    )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var goalTypeColor: Color {
        switch goal.type {
        case .calories: return .orange
        case .protein: return .blue
        case .carbs: return .green
        case .fat: return .yellow
        case .fiber: return .purple
        case .sugar: return .pink
        case .sodium: return .red
        }
    }
    
    private var goalTypeIcon: String {
        switch goal.type {
        case .calories: return "flame"
        case .protein: return "dumbbell"
        case .carbs: return "leaf"
        case .fat: return "drop"
        case .fiber: return "leaf.fill"
        case .sugar: return "heart"
        case .sodium: return "drop.fill"
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Dietary Recommendation
struct DietaryRecommendation {
    let title: String
    let message: String
    let type: RecommendationType
    let goalType: DietaryGoal.GoalType
    
    enum RecommendationType: String {
        case boost
        case reduce
        case maintain
    }
}

// MARK: - Dietary Recommendation Card
struct DietaryRecommendationCard: View {
    let recommendation: DietaryRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            // Recommendation Icon
            ZStack {
                Circle()
                    .fill(recommendationColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: recommendationIcon)
                    .foregroundColor(recommendationColor)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(recommendation.message)
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
    
    private var recommendationColor: Color {
        switch recommendation.type {
        case .boost: return .green
        case .reduce: return .red
        case .maintain: return .blue
        }
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .boost: return "arrow.up.circle"
        case .reduce: return "arrow.down.circle"
        case .maintain: return "checkmark.circle"
        }
    }
}

// MARK: - Nutrition Tip
struct NutritionTip {
    let title: String
    let message: String
    let icon: String
    let color: Color
}

// MARK: - Nutrition Tip Card
struct NutritionTipCard: View {
    let tip: NutritionTip
    
    var body: some View {
        HStack(spacing: 12) {
            // Tip Icon
            ZStack {
                Circle()
                    .fill(tip.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: tip.icon)
                    .foregroundColor(tip.color)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(tip.message)
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
}

// MARK: - Add Dietary Goal View
struct AddDietaryGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedGoalType: DietaryGoal.GoalType = .calories
    @State private var targetValue: String = ""
    @State private var currentValue: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Goal Type Selection
                    goalTypeSection
                    
                    // Target Value
                    targetValueSection
                    
                    // Current Value
                    currentValueSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Goal")
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
                        saveGoal()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
    }
    
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Type")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DietaryGoal.GoalType.allCases, id: \.self) { goalType in
                    GoalTypeButton(
                        goalType: goalType,
                        isSelected: selectedGoalType == goalType
                    ) {
                        selectedGoalType = goalType
                    }
                }
            }
        }
    }
    
    private var targetValueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Value")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("Enter target value", text: $targetValue)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
        }
    }
    
    private var currentValueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Value (Optional)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("Enter current value", text: $currentValue)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
        }
    }
    
    private func saveGoal() {
        guard let target = Double(targetValue) else { return }
        let current = Double(currentValue) ?? 0
        
        let newGoal = DietaryGoal(
            type: selectedGoalType,
            target: target,
            current: current,
            unit: getUnit(for: selectedGoalType),
            isActive: true
        )
        
        appState.dietaryGoals.append(newGoal)
        dismiss()
    }
    
    private func getUnit(for goalType: DietaryGoal.GoalType) -> String {
        switch goalType {
        case .calories: return "cal"
        case .protein, .carbs, .fat, .fiber, .sugar, .sodium: return "g"
        }
    }
}

// MARK: - Goal Type Button
struct GoalTypeButton: View {
    let goalType: DietaryGoal.GoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? goalTypeColor : goalTypeColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: goalTypeIcon)
                        .foregroundColor(isSelected ? .white : goalTypeColor)
                        .font(.title3)
                }
                
                Text(goalType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? goalTypeColor.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var goalTypeColor: Color {
        switch goalType {
        case .calories: return .orange
        case .protein: return .blue
        case .carbs: return .green
        case .fat: return .yellow
        case .fiber: return .purple
        case .sugar: return .pink
        case .sodium: return .red
        }
    }
    
    private var goalTypeIcon: String {
        switch goalType {
        case .calories: return "flame"
        case .protein: return "dumbbell"
        case .carbs: return "leaf"
        case .fat: return "drop"
        case .fiber: return "leaf.fill"
        case .sugar: return "heart"
        case .sodium: return "drop.fill"
        }
    }
}

// MARK: - Goal Detail View
struct GoalDetailView: View {
    let goal: DietaryGoal
    @Environment(\.dismiss) private var dismiss
    @State private var updatedCurrent: String = ""
    
    var progress: Double {
        goal.current / goal.target
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Overview
                        progressOverviewSection
                        
                        // Goal Details
                        goalDetailsSection
                        
                        // Update Progress
                        updateProgressSection
                        
                        // Recommendations
                        recommendationsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle(goal.type.rawValue)
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
        .onAppear {
            updatedCurrent = String(goal.current)
        }
    }
    
    private var progressOverviewSection: some View {
        VStack(spacing: 16) {
            // Large Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text("\(Int(goal.current)) / \(Int(goal.target)) \(goal.unit)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    private var goalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Details")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(label: "Type", value: goal.type.rawValue)
                DetailRow(label: "Target", value: "\(Int(goal.target)) \(goal.unit)")
                DetailRow(label: "Current", value: "\(Int(goal.current)) \(goal.unit)")
                DetailRow(label: "Remaining", value: "\(Int(max(0, goal.target - goal.current))) \(goal.unit)")
                DetailRow(label: "Status", value: goal.isActive ? "Active" : "Inactive")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var updateProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update Progress")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                TextField("Current value", text: $updatedCurrent)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                
                Button("Update Progress") {
                    if let newValue = Double(updatedCurrent) {
                        // TODO: Update goal progress
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.lumoGreen)
                .cornerRadius(12)
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let recommendations = getRecommendations()
            
            VStack(spacing: 12) {
                ForEach(recommendations, id: \.title) { recommendation in
                    DietaryRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getRecommendations() -> [DietaryRecommendation] {
        var recommendations: [DietaryRecommendation] = []
        
        if progress < 0.5 {
            recommendations.append(DietaryRecommendation(
                title: "Boost Your \(goal.type.rawValue)",
                message: "You're only \(Int(progress * 100))% to your goal. Try adding more \(goal.type.rawValue.lowercased())-rich foods to your diet.",
                type: .boost,
                goalType: goal.type
            ))
        } else if progress > 1.2 {
            recommendations.append(DietaryRecommendation(
                title: "Reduce \(goal.type.rawValue) Intake",
                message: "You're \(Int((progress - 1) * 100))% over your goal. Consider healthier alternatives.",
                type: .reduce,
                goalType: goal.type
            ))
        } else {
            recommendations.append(DietaryRecommendation(
                title: "Maintain Your Progress",
                message: "Great job! You're on track with your \(goal.type.rawValue.lowercased()) goal.",
                type: .maintain,
                goalType: goal.type
            ))
        }
        
        return recommendations
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Dietary Recommendations View
struct DietaryRecommendationsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dietary Recommendations")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Personalized recommendations based on your goals and preferences.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        // Recommendations List
                        LazyVStack(spacing: 16) {
                            ForEach(getAllRecommendations(), id: \.title) { recommendation in
                                DetailedRecommendationCard(recommendation: recommendation)
                            }
                        }
                        .padding()
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Recommendations")
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
    
    private func getAllRecommendations() -> [DietaryRecommendation] {
        return [
            DietaryRecommendation(
                title: "Increase Protein Intake",
                message: "Add lean proteins like chicken, fish, tofu, or legumes to help build muscle and stay full longer.",
                type: .boost,
                goalType: .protein
            ),
            DietaryRecommendation(
                title: "Reduce Added Sugars",
                message: "Limit processed foods and sugary drinks. Choose whole fruits instead of fruit juices.",
                type: .reduce,
                goalType: .sugar
            ),
            DietaryRecommendation(
                title: "Boost Fiber Consumption",
                message: "Include more whole grains, fruits, vegetables, and legumes in your meals.",
                type: .boost,
                goalType: .fiber
            ),
            DietaryRecommendation(
                title: "Monitor Sodium Intake",
                message: "Read nutrition labels and choose low-sodium alternatives when possible.",
                type: .reduce,
                goalType: .sodium
            )
        ]
    }
}

// MARK: - Detailed Recommendation Card
struct DetailedRecommendationCard: View {
    let recommendation: DietaryRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(recommendationColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: recommendationIcon)
                        .foregroundColor(recommendationColor)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(recommendation.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(recommendationColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recommendationColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // Message
            Text(recommendation.message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(nil)
            
            // Action Button
            Button("Get Food Suggestions") {
                // TODO: Implement food suggestions
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
    
    private var recommendationColor: Color {
        switch recommendation.type {
        case .boost: return .green
        case .reduce: return .red
        case .maintain: return .blue
        }
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .boost: return "arrow.up.circle"
        case .reduce: return "arrow.down.circle"
        case .maintain: return "checkmark.circle"
        }
    }
} 