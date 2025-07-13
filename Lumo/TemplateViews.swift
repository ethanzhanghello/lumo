//
//  TemplateViews.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

// MARK: - Save Template View
// Note: SaveTemplateView is defined in MealPlanningView.swift to avoid duplication

// MARK: - Load Template View
struct LoadTemplateView: View {
    let onLoad: (MealPlanTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var showingConfirmation = false
    @State private var selectedTemplate: MealPlanTemplate?
    
    private let availableTags = ["Vegan", "Vegetarian", "Low Carb", "High Protein", "Budget", "Quick", "Family", "Healthy", "Gluten-Free", "Dairy-Free"]
    
    var filteredTemplates: [MealPlanTemplate] {
        var templates = appState.mealPlanTemplates
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.lowercased().contains(searchText.lowercased()) ||
                template.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        if let selectedTag = selectedTag {
            templates = templates.filter { template in
                template.tags.contains(selectedTag)
            }
        }
        
        return templates
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search Bar
                    searchSection
                    
                    // Tags Filter
                    tagsFilterSection
                    
                    // Templates List
                    templatesListSection
                }
                .padding()
            }
            .navigationTitle("Load Template")
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
        .confirmationDialog(
            "Replace Current Plan",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                if let template = selectedTemplate {
                    onLoad(template)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will replace your current meal plan. Continue?")
        }
    }
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search templates...", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var tagsFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(
                    name: "All",
                    isSelected: selectedTag == nil,
                    onToggle: { _ in
                        selectedTag = nil
                    }
                )
                
                ForEach(availableTags, id: \.self) { tag in
                    TagChip(
                        name: tag,
                        isSelected: selectedTag == tag,
                        onToggle: { isSelected in
                            selectedTag = isSelected ? tag : nil
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var templatesListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTemplates, id: \.id) { template in
                    TemplateCard(
                        template: template,
                        onLoad: {
                            selectedTemplate = template
                            showingConfirmation = true
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let name: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: MealPlanTemplate
    let onLoad: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button("Load") {
                    onLoad()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lumoGreen)
                .cornerRadius(8)
            }
            
            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(.lumoGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.lumoGreen.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Meal Preview
            HStack {
                Text("\(template.meals.count) meals")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(template.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 

// MARK: - Nutrition Analysis View
struct NutritionAnalysisView: View {
    let mealPlans: [MealPlan]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProfile: NutritionProfile = .standard
    
    private var dailySummaries: [NutritionSummary] {
        mealPlans.map { plan in
            NutritionSummary.fromMeals(plan.meals)
        }
    }
    private var weeklySummary: NutritionSummary {
        NutritionSummary.aggregate(dailySummaries)
    }
    private var targets: NutritionTargets {
        selectedProfile.targets
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picker
                        profilePicker
                        // Daily Bars
                        ForEach(Array(dailySummaries.enumerated()), id: \.offset) { idx, summary in
                            NutritionDayBar(
                                dayIndex: idx,
                                summary: summary,
                                targets: targets
                            )
                        }
                        // Weekly Summary
                        weeklySummaryCard
                        // Alerts
                        nutritionAlerts
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var profilePicker: some View {
        HStack(spacing: 12) {
            Text("Profile:")
                .font(.headline)
                .foregroundColor(.white)
            Picker("Profile", selection: $selectedProfile) {
                ForEach(NutritionProfile.allCases, id: \.self) { profile in
                    Text(profile.displayName).tag(profile)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Summary")
                .font(.headline)
                .foregroundColor(.white)
            NutritionMacroBars(summary: weeklySummary, targets: targets, isWeekly: true)
            HStack(spacing: 16) {
                macroStat("Calories", value: weeklySummary.calories, target: targets.calories * 7, icon: "flame")
                macroStat("Protein", value: weeklySummary.protein, target: targets.protein * 7, icon: "bolt")
                macroStat("Carbs", value: weeklySummary.carbs, target: targets.carbs * 7, icon: "leaf")
                macroStat("Fat", value: weeklySummary.fat, target: targets.fat * 7, icon: "drop")
                macroStat("Fiber", value: weeklySummary.fiber, target: targets.fiber * 7, icon: "arrow.up")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func macroStat(_ name: String, value: Double, target: Double, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.lumoGreen)
            Text("\(Int(value))")
                .font(.headline)
                .foregroundColor(.white)
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
            Text("/ \(Int(target))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var nutritionAlerts: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(weeklySummary.alerts(targets: targets), id: \.self) { alert in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(alert)
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Nutrition Profile
enum NutritionProfile: String, CaseIterable {
    case standard, lowCarb, muscleGain
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .lowCarb: return "Low-Carb"
        case .muscleGain: return "Muscle Gain"
        }
    }
    var targets: NutritionTargets {
        switch self {
        case .standard:
            return NutritionTargets(calories: 2000, protein: 75, carbs: 250, fat: 70, fiber: 28)
        case .lowCarb:
            return NutritionTargets(calories: 1800, protein: 90, carbs: 100, fat: 80, fiber: 28)
        case .muscleGain:
            return NutritionTargets(calories: 2500, protein: 130, carbs: 300, fat: 80, fiber: 30)
        }
    }
}

struct NutritionTargets {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
}

// MARK: - Nutrition Summary
struct NutritionSummary {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    
    static func fromMeals(_ meals: [MealPlan.Meal]) -> NutritionSummary {
        var total = NutritionSummary(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)
        for meal in meals {
            if let recipe = meal.recipe {
                total.calories += Double(recipe.nutritionInfo.calories)
                total.protein += recipe.nutritionInfo.protein
                total.carbs += recipe.nutritionInfo.carbs
                total.fat += recipe.nutritionInfo.fat
                total.fiber += recipe.nutritionInfo.fiber ?? 0
            }
        }
        return total
    }
    static func aggregate(_ summaries: [NutritionSummary]) -> NutritionSummary {
        summaries.reduce(NutritionSummary(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)) { acc, s in
            NutritionSummary(
                calories: acc.calories + s.calories,
                protein: acc.protein + s.protein,
                carbs: acc.carbs + s.carbs,
                fat: acc.fat + s.fat,
                fiber: acc.fiber + s.fiber
            )
        }
    }
    func alerts(targets: NutritionTargets) -> [String] {
        var alerts: [String] = []
        if calories < targets.calories * 7 * 0.8 {
            alerts.append("Low in calories this week — consider adding more energy-dense meals.")
        }
        if protein < targets.protein * 7 * 0.8 {
            alerts.append("Low in protein this week — consider adding eggs, chicken, or beans.")
        }
        if fiber < targets.fiber * 7 * 0.7 {
            alerts.append("Low in fiber this week — consider adding beans or greens.")
        }
        if fat > targets.fat * 7 * 1.2 {
            alerts.append("High in fat this week — consider reducing oils or fatty meats.")
        }
        return alerts
    }
}

// MARK: - Nutrition Macro Bars
struct NutritionMacroBars: View {
    let summary: NutritionSummary
    let targets: NutritionTargets
    var isWeekly: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            macroBar(name: "Calories", value: summary.calories, target: targets.calories * (isWeekly ? 7 : 1), color: .orange, icon: "flame")
            macroBar(name: "Protein", value: summary.protein, target: targets.protein * (isWeekly ? 7 : 1), color: .blue, icon: "bolt")
            macroBar(name: "Carbs", value: summary.carbs, target: targets.carbs * (isWeekly ? 7 : 1), color: .green, icon: "leaf")
            macroBar(name: "Fat", value: summary.fat, target: targets.fat * (isWeekly ? 7 : 1), color: .pink, icon: "drop")
            macroBar(name: "Fiber", value: summary.fiber, target: targets.fiber * (isWeekly ? 7 : 1), color: .purple, icon: "arrow.up")
        }
    }
    
    private func macroBar(name: String, value: Double, target: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(name)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value))/\(Int(target))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            ProgressView(value: min(value/target, 1.2))
                .accentColor(color)
                .frame(height: 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

// MARK: - Nutrition Day Bar
struct NutritionDayBar: View {
    let dayIndex: Int
    let summary: NutritionSummary
    let targets: NutritionTargets
    
    private var dayName: String {
        let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(dayName) — Daily Nutrition")
                .font(.subheadline)
                .foregroundColor(.white)
            NutritionMacroBars(summary: summary, targets: targets)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }
} 