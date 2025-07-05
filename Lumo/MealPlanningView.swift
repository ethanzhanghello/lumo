//
//  MealPlanningView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct MealPlanningView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var showingAddMeal = false
    @State private var showingRecipePicker = false
    @State private var selectedMealType: MealPlan.Meal.MealType = .breakfast
    @State private var showingShoppingList = false
    @State private var generatedShoppingList: [GroceryItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Calendar View
                        calendarSection
                        
                        // Today's Meals
                        todaysMealsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Weekly Overview
                        weeklyOverviewSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Meal Planning")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Meal") {
                        showingAddMeal = true
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(selectedDate: selectedDate, selectedMealType: selectedMealType)
        }
        .sheet(isPresented: $showingRecipePicker) {
            RecipePickerView { recipe in
                addRecipeToMeal(recipe)
            }
        }
        .sheet(isPresented: $showingShoppingList) {
            GeneratedShoppingListView(items: generatedShoppingList)
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
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Date")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .accentColor(.lumoGreen)
                .colorScheme(.dark)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Today's Meals Section
    private var todaysMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Meals")
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
            
            if let todaysPlan = getTodaysMealPlan() {
                ForEach(todaysPlan.meals) { meal in
                    MealCard(meal: meal)
                }
            } else {
                Text("No meals planned for today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
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
                    title: "Generate Shopping List",
                    icon: "cart",
                    color: .lumoGreen
                ) {
                    generateShoppingList()
                }
                
                QuickActionCard(
                    title: "Scale Recipes",
                    icon: "arrow.up.arrow.down",
                    color: .blue
                ) {
                    // TODO: Implement recipe scaling
                }
                
                QuickActionCard(
                    title: "Leftover Recipes",
                    icon: "leaf",
                    color: .orange
                ) {
                    // TODO: Implement leftover suggestions
                }
                
                QuickActionCard(
                    title: "Nutrition Analysis",
                    icon: "chart.bar",
                    color: .purple
                ) {
                    // TODO: Implement nutrition analysis
                }
            }
        }
    }
    
    // MARK: - Weekly Overview Section
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                        WeeklyDayCard(
                            date: date,
                            mealCount: getMealCount(for: date)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getTodaysMealPlan() -> MealPlan? {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.mealPlans.first { plan in
            Calendar.current.isDate(plan.date, inSameDayAs: today)
        }
    }
    
    private func getMealCount(for date: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return appState.mealPlans.first { plan in
            Calendar.current.isDate(plan.date, inSameDayAs: startOfDay)
        }?.meals.count ?? 0
    }
    
    private func addRecipeToMeal(_ recipe: Recipe) {
        // TODO: Implement adding recipe to meal plan
    }
    
    private func generateShoppingList() {
        let allMealPlans = appState.mealPlans.filter { plan in
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weekEnd = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
            return plan.date >= weekStart && plan.date <= weekEnd
        }
        
        var allIngredients: [GroceryItem] = []
        
        for plan in allMealPlans {
            for meal in plan.meals {
                allIngredients.append(contentsOf: meal.ingredients)
            }
        }
        
        // Group and combine ingredients
        let groupedIngredients = Dictionary(grouping: allIngredients) { $0.name }
        generatedShoppingList = groupedIngredients.map { _, items in
            let firstItem = items.first!
            return GroceryItem(
                name: firstItem.name,
                description: firstItem.description,
                price: firstItem.price,
                category: firstItem.category,
                aisle: firstItem.aisle,
                brand: firstItem.brand
            )
        }
        
        showingShoppingList = true
    }
}

// MARK: - Meal Card
struct MealCard: View {
    let meal: MealPlan.Meal
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal Type Icon
            ZStack {
                Circle()
                    .fill(mealTypeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: mealTypeIcon)
                    .foregroundColor(mealTypeColor)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if let recipe = meal.recipe {
                    Text(recipe.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let customMeal = meal.customMeal {
                    Text(customMeal)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text("\(meal.ingredients.count) ingredients")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Edit meal
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.lumoGreen)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypeColor: Color {
        switch meal.type {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        }
    }
    
    private var mealTypeIcon: String {
        switch meal.type {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
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

// MARK: - Weekly Day Card
struct WeeklyDayCard: View {
    let date: Date
    let mealCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayOfWeek)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("\(mealCount) meals")
                .font(.caption2)
                .foregroundColor(.lumoGreen)
        }
        .frame(width: 60, height: 80)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Add Meal View
struct AddMealView: View {
    let selectedDate: Date
    let selectedMealType: MealPlan.Meal.MealType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecipe: Recipe?
    @State private var customMeal = ""
    @State private var showingRecipePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Meal Type Selection
                    mealTypeSection
                    
                    // Recipe or Custom Meal
                    mealContentSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Meal")
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
                        saveMeal()
                    }
                    .foregroundColor(.lumoGreen)
                }
            }
        }
        .sheet(isPresented: $showingRecipePicker) {
            RecipePickerView { recipe in
                selectedRecipe = recipe
            }
        }
    }
    
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Type")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MealPlan.Meal.MealType.allCases, id: \.self) { mealType in
                    MealTypeButton(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    )
                }
            }
        }
    }
    
    private var mealContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Content")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Button("Choose Recipe") {
                    showingRecipePicker = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.lumoGreen.opacity(0.2))
                .cornerRadius(12)
                
                Text("OR")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                
                TextField("Enter custom meal description", text: $customMeal)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func saveMeal() {
        // TODO: Implement saving meal to meal plan
        dismiss()
    }
}

// MARK: - Meal Type Button
struct MealTypeButton: View {
    let mealType: MealPlan.Meal.MealType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? mealTypeColor : mealTypeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: mealTypeIcon)
                    .foregroundColor(isSelected ? .white : mealTypeColor)
                    .font(.title3)
            }
            
            Text(mealType.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isSelected ? mealTypeColor.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypeColor: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .purple
        case .snack: return .blue
        }
    }
    
    private var mealTypeIcon: String {
        switch mealType {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
}

// MARK: - Recipe Picker View
struct RecipePickerView: View {
    let onRecipeSelected: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return RecipeDatabase.recipes
        } else {
            return RecipeDatabase.recipes.filter { recipe in
                recipe.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search recipes...", text: $searchText)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recipe List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecipes, id: \.id) { recipe in
                                RecipePickerCard(recipe: recipe) {
                                    onRecipeSelected(recipe)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Recipe Picker Card
struct RecipePickerCard: View {
    let recipe: Recipe
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Recipe Image Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(recipe.ingredients.count) ingredients • \(recipe.servings) servings")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Generated Shopping List View
struct GeneratedShoppingListView: View {
    let items: [GroceryItem]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Summary
                    VStack(spacing: 8) {
                        Text("Generated Shopping List")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(items.count) items from your meal plan")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    // Items List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(items, id: \.id) { item in
                                GeneratedItemRow(item: item)
                            }
                        }
                        .padding()
                    }
                    
                    // Add to List Button
                    Button("Add All to Grocery List") {
                        for item in items {
                            appState.groceryList.addItem(item)
                        }
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.lumoGreen)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Shopping List")
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

// MARK: - Generated Item Row
struct GeneratedItemRow: View {
    let item: GroceryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(item.category)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("$\(item.price, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.lumoGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 