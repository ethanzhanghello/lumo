//
//  MealPlanningView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct MealPlanningView: View {
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var showingAddMeal = false
    @State private var showingAutoFill = false
    @State private var showingNutritionAnalysis = false
    @State private var showingGroceryList = false
    @State private var selectedMealType: MealType = .dinner
    @State private var weekStartDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Weekly Calendar
                        weeklyCalendarSection
                        
                        // Daily Meal View
                        dailyMealSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddMeal) {
            Text("Add Meal View - Coming Soon")
                .foregroundColor(.white)
        }
        .sheet(isPresented: $showingAutoFill) {
            AutoFillView()
        }
        .sheet(isPresented: $showingNutritionAnalysis) {
            NutritionAnalysisView(mealPlans: [
                MealPlan(
                    date: weekStartDate,
                    meals: mealManager.mealsForWeek(starting: weekStartDate).map { meal in
                        MealPlan.Meal(
                            type: MealPlan.Meal.MealType(rawValue: meal.type.rawValue) ?? .dinner,
                            recipe: meal.recipe,
                            customMeal: meal.customMeal,
                            ingredients: meal.recipe?.ingredients.map { ingredient in
                                GroceryItem(
                                    name: ingredient.name,
                                    description: ingredient.notes ?? "",
                                    price: ingredient.estimatedPrice,
                                    category: "",
                                    aisle: ingredient.aisle,
                                    brand: ""
                                )
                            } ?? []
                        )
                    },
                    notes: nil
                )
            ])
        }
        .sheet(isPresented: $showingGroceryList) {
            Text("Generated Grocery List View - Coming Soon")
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan Your Meals")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Create meal plans, scale recipes, and generate shopping lists automatically.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Weekly Calendar Section
    private var weeklyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Previous") {
                    weekStartDate = Calendar.current.date(byAdding: .day, value: -7, to: weekStartDate) ?? weekStartDate
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
                
                Button("Next") {
                    weekStartDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
                }
                .foregroundColor(.lumoGreen)
                .font(.caption)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStartDate) ?? Date()
                        WeeklyDayCard(
                            date: date,
                            mealCount: mealManager.mealCount(for: date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: mealManager.selectedDate),
                            onTap: {
                                mealManager.selectedDate = date
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Daily Meal Section
    private var dailyMealSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Meals for \(mealManager.selectedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Add Meal") {
                    showingAddMeal = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            let meals = mealManager.meals(for: mealManager.selectedDate)
            
            if meals.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(meals) { meal in
                        MealCard(meal: meal) {
                            // Edit meal
                        } onDelete: {
                            print("Deleting meal: \(meal.recipeName)")
                            let beforeCount = mealManager.meals(for: mealManager.selectedDate).count
                            mealManager.removeMeal(meal)
                            let afterCount = mealManager.meals(for: mealManager.selectedDate).count
                            print("Meal deletion: \(beforeCount) -> \(afterCount) meals")
                            // Force UI update
                            DispatchQueue.main.async {
                                mealManager.objectWillChange.send()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No meals planned for today")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tap 'Add Meal' to start planning your day")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Auto-Fill Week",
                    icon: "wand.and.stars",
                    color: .purple
                ) {
                    showingAutoFill = true
                }
                
                QuickActionCard(
                    title: "Shopping List",
                    icon: "cart",
                    color: .lumoGreen
                ) {
                    showingGroceryList = true
                }
                
                QuickActionCard(
                    title: "Nutrition",
                    icon: "chart.bar",
                    color: .blue
                ) {
                    showingNutritionAnalysis = true
                }
                
                QuickActionCard(
                    title: "Leftovers",
                    icon: "leaf",
                    color: .orange
                ) {
                    // TODO: Implement leftovers feature
                }
            }
        }
    }
}

// MARK: - Weekly Day Card
struct WeeklyDayCard: View {
    let date: Date
    let mealCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(dayOfWeek)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if mealCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(mealCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(Color.lumoGreen)
                                .frame(width: 6, height: 6)
                        }
                        
                        if mealCount > 3 {
                            Text("+\(mealCount - 3)")
                                .font(.caption2)
                                .foregroundColor(.lumoGreen)
                        }
                    }
                } else {
                    Text("No meals")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 70, height: 90)
            .background(isSelected ? Color.lumoGreen.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.lumoGreen : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Card
struct MealCard: View {
    let meal: Meal
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal Type Icon
            ZStack {
                Circle()
                    .fill(meal.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(meal.type.emoji)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(meal.recipeName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(meal.ingredients.count) ingredients • \(meal.servings) servings")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.lumoGreen)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete Meal",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this meal?")
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
} 