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
    @State private var showingEditMeal = false
    @State private var selectedMealForEdit: MealPlan.Meal?
    @State private var showingLeftoverRecipes = false
    @State private var showingAddNote = false
    @State private var showingSaveTemplate = false
    @State private var showingLoadTemplate = false
    @State private var showingAutoFill = false
    @State private var showingNutritionAnalysis = false
    
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
                    HStack {
                        Button("Save Template") {
                            showingSaveTemplate = true
                        }
                        .foregroundColor(.blue)
                        
                        Button("Load Template") {
                            showingLoadTemplate = true
                        }
                        .foregroundColor(.orange)
                        
                        Button("Add Meal") {
                            showingAddMeal = true
                        }
                        .foregroundColor(.lumoGreen)
                    }
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
        .sheet(isPresented: $showingEditMeal) {
            if let meal = selectedMealForEdit {
                EditMealView(
                    meal: meal,
                    onSave: { updatedMeal in
                        updateMeal(updatedMeal)
                    },
                    onDelete: {
                        deleteMeal(meal)
                    }
                )
            }
        }
        .sheet(isPresented: $showingLeftoverRecipes) {
            LeftoverRecipeView()
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(date: selectedDate) { note in
                saveNote(note, for: selectedDate)
            }
        }
        .sheet(isPresented: $showingSaveTemplate) {
            SaveTemplateView { template in
                saveTemplate(template)
            }
        }
        .sheet(isPresented: $showingLoadTemplate) {
            LoadTemplateView { template in
                loadTemplate(template)
            }
        }
        .sheet(isPresented: $showingAutoFill) {
            AutoFillView { mealPlan in
                applyAutoFilledMealPlan(mealPlan)
            }
        }
        .sheet(isPresented: $showingNutritionAnalysis) {
            NutritionAnalysisView(mealPlans: appState.mealPlans)
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
                    MealCard(
                        meal: meal,
                        onEdit: {
                            selectedMealForEdit = meal
                            showingEditMeal = true
                        },
                        onDelete: {
                            deleteMeal(meal)
                        }
                    )
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
                    title: "Auto-Fill My Week",
                    icon: "wand.and.stars",
                    color: .purple
                ) {
                    showingAutoFill = true
                }
                
                QuickActionCard(
                    title: "Generate Shopping List",
                    icon: "cart",
                    color: .lumoGreen
                ) {
                    generateShoppingList()
                }
                
                QuickActionCard(
                    title: "Use Leftovers",
                    icon: "leaf",
                    color: .orange
                ) {
                    showingLeftoverRecipes = true
                }
                
                QuickActionCard(
                    title: "Scale Recipes",
                    icon: "arrow.up.arrow.down",
                    color: .blue
                ) {
                    // TODO: Implement recipe scaling
                }
                
                QuickActionCard(
                    title: "Nutrition Analysis",
                    icon: "chart.bar",
                    color: .purple
                ) {
                    showingNutritionAnalysis = true
                }
            }
        }
    }
    
    // MARK: - Weekly Overview Section
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Add Note") {
                    showingAddNote = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                        WeeklyDayCard(
                            date: date,
                            mealCount: getMealCount(for: date),
                            note: getNote(for: date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            onTap: {
                                selectedDate = date
                            },
                            onLongPress: {
                                // TODO: Enable drag mode
                            }
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
    
    private func getNote(for date: Date) -> String? {
        let targetDate = Calendar.current.startOfDay(for: date)
        if let plan = appState.mealPlans.first(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            return plan.notes
        }
        return nil
    }
    
    private func saveNote(_ note: String, for date: Date) {
        let targetDate = Calendar.current.startOfDay(for: date)
        if let planIndex = appState.mealPlans.firstIndex(where: { plan in
            Calendar.current.isDate(plan.date, inSameDayAs: targetDate)
        }) {
            appState.mealPlans[planIndex].notes = note
        } else {
            // Create new meal plan for this date with just the note
            let newPlan = MealPlan(date: targetDate, meals: [], notes: note)
            appState.mealPlans.append(newPlan)
        }
    }
    
    private func saveTemplate(_ template: MealPlanTemplate) {
        appState.mealPlanTemplates.append(template)
    }
    
    private func loadTemplate(_ template: MealPlanTemplate) {
        // Clear current meal plans and load template
        appState.mealPlans.removeAll()
        
        // Create meal plans for the next 7 days using the template
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let plan = MealPlan(
                date: date,
                meals: template.meals,
                notes: template.notes
            )
            appState.mealPlans.append(plan)
        }
    }
    
    private func applyAutoFilledMealPlan(_ mealPlan: [MealPlan]) {
        // Clear current meal plans and apply the generated plan
        appState.mealPlans.removeAll()
        appState.mealPlans = mealPlan
    }
    
    private func addRecipeToMeal(_ recipe: Recipe) {
        // TODO: Implement adding recipe to meal plan
    }
    
    private func updateMeal(_ updatedMeal: MealPlan.Meal) {
        let today = Calendar.current.startOfDay(for: Date())
        if let planIndex = appState.mealPlans.firstIndex(where: { plan in
            Calendar.current.isDate(plan.date, inSameDayAs: today)
        }) {
            if let mealIndex = appState.mealPlans[planIndex].meals.firstIndex(where: { $0.id == updatedMeal.id }) {
                appState.mealPlans[planIndex].meals[mealIndex] = updatedMeal
            }
        }
    }
    
    private func deleteMeal(_ meal: MealPlan.Meal) {
        let today = Calendar.current.startOfDay(for: Date())
        if let planIndex = appState.mealPlans.firstIndex(where: { plan in
            Calendar.current.isDate(plan.date, inSameDayAs: today)
        }) {
            appState.mealPlans[planIndex].meals.removeAll { $0.id == meal.id }
        }
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
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
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
    let note: String?
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
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
            
            if let note = note {
                Text(note)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 70, height: 90)
        .background(isSelected ? Color.lumoGreen.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.lumoGreen : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
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
    @State private var showingSpoonacularSearch = false
    
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
                    
                    // Spoonacular Search Button
                    Button(action: { showingSpoonacularSearch = true }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Search Spoonacular Recipes")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
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
            .sheet(isPresented: $showingSpoonacularSearch) {
                SpoonacularRecipeView { recipe in
                    onRecipeSelected(recipe)
                    dismiss()
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
    @State private var selectedItems: Set<UUID> = []
    @State private var showingPantryCheck = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Summary Header
                    summaryHeader
                    
                    // Sticky Ingredient Count
                    stickyIngredientCount
                    
                    // Items List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                                categorySection(category: category)
                            }
                        }
                        .padding()
                    }
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .navigationTitle("Shopping List Review")
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
            // Select all items by default
            selectedItems = Set(items.map { $0.id })
        }
    }
    
    private var summaryHeader: some View {
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
    }
    
    private var stickyIngredientCount: some View {
        HStack {
            Text("\(selectedItems.count) of \(items.count) items selected")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.lumoGreen)
            
            Spacer()
            
            Button("Select All") {
                if selectedItems.count == items.count {
                    selectedItems.removeAll()
                } else {
                    selectedItems = Set(items.map { $0.id })
                }
            }
            .font(.caption)
            .foregroundColor(.lumoGreen)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    private var groupedItems: [String: [GroceryItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    private func categorySection(category: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(groupedItems[category] ?? [], id: \.id) { item in
                    EnhancedItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item.id),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedItems.insert(item.id)
                            } else {
                                selectedItems.remove(item.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Check Pantry") {
                showingPantryCheck = true
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
            
            Button("Add Selected to Grocery List") {
                let selectedGroceryItems = items.filter { selectedItems.contains($0.id) }
                for item in selectedGroceryItems {
                    appState.groceryList.addItem(item)
                }
                dismiss()
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(selectedItems.isEmpty ? Color.gray : Color.lumoGreen)
            .cornerRadius(12)
            .disabled(selectedItems.isEmpty)
        }
        .padding()
    }
}

// MARK: - Enhanced Item Row
struct EnhancedItemRow: View {
    let item: GroceryItem
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onToggle(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .lumoGreen : .gray)
                    .font(.title3)
            }
            
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
                
                Text("$\(item.price, specifier: "%.2f") • \(item.category)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Leftover Recipe View
struct LeftoverRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedIngredients: Set<String> = []
    @State private var suggestedRecipes: [Recipe] = []
    @State private var showingRecipeDetail = false
    @State private var selectedRecipe: Recipe?
    
    // Sample pantry items - in a real app, this would come from the pantry manager
    private let pantryItems = [
        "Rice", "Pasta", "Chicken", "Eggs", "Onions", "Garlic", "Tomatoes", 
        "Cheese", "Milk", "Butter", "Flour", "Olive Oil", "Broccoli", "Carrots",
        "Potatoes", "Spinach", "Mushrooms", "Bell Peppers", "Lemons", "Herbs"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Ingredient Selection
                    ingredientSelectionSection
                    
                    // Suggested Recipes
                    if !suggestedRecipes.isEmpty {
                        suggestedRecipesSection
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Use Leftovers")
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
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("What do you have?")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select ingredients you have available to find recipes")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    private var ingredientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Available Ingredients")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Select All") {
                    if selectedIngredients.count == pantryItems.count {
                        selectedIngredients.removeAll()
                    } else {
                        selectedIngredients = Set(pantryItems)
                    }
                    findRecipes()
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(pantryItems, id: \.self) { ingredient in
                    IngredientChip(
                        name: ingredient,
                        isSelected: selectedIngredients.contains(ingredient),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedIngredients.insert(ingredient)
                            } else {
                                selectedIngredients.remove(ingredient)
                            }
                            findRecipes()
                        }
                    )
                }
            }
        }
    }
    
    private var suggestedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Recipes")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(suggestedRecipes, id: \.id) { recipe in
                    LeftoverRecipeCard(
                        recipe: recipe,
                        availableIngredients: selectedIngredients,
                        onAddToPlan: {
                            addRecipeToPlan(recipe)
                        }
                    )
                }
            }
        }
    }
    
    private func findRecipes() {
        guard !selectedIngredients.isEmpty else {
            suggestedRecipes = []
            return
        }
        
        let recipes = RecipeDatabase.recipes
        let availableIngredients = selectedIngredients.map { $0.lowercased() }
        
        // Find recipes that use the most available ingredients
        let scoredRecipes = recipes.map { recipe in
            let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
            let matchingIngredients = recipeIngredients.filter { recipeIngredient in
                availableIngredients.contains { availableIngredient in
                    availableIngredient.contains(recipeIngredient) || recipeIngredient.contains(availableIngredient)
                }
            }
            let matchScore = Double(matchingIngredients.count) / Double(recipeIngredients.count)
            return (recipe: recipe, score: matchScore, matches: matchingIngredients.count)
        }
        
        // Sort by match score and take top 3
        suggestedRecipes = scoredRecipes
            .filter { $0.score >= 0.3 } // At least 30% match
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.recipe }
    }
    
    private func addRecipeToPlan(_ recipe: Recipe) {
        let today = Calendar.current.startOfDay(for: Date())
        let meal = MealPlan.Meal(
            type: .dinner,
            recipe: recipe,
            customMeal: nil,
            ingredients: recipe.ingredients.map { ing in
                GroceryItem(
                    name: ing.name,
                    description: ing.notes ?? "",
                    price: ing.estimatedPrice,
                    category: "Produce",
                    aisle: ing.aisle,
                    brand: ""
                )
            }
        )
        
        if let idx = appState.mealPlans.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            appState.mealPlans[idx].meals.append(meal)
        } else {
            appState.mealPlans.append(MealPlan(date: today, meals: [meal], notes: nil))
        }
        
        dismiss()
    }
}

// MARK: - Add Note View
struct AddNoteView: View {
    let date: Date
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Date Display
                    VStack(spacing: 8) {
                        Text(dateFormatter.string(from: date))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Add a note for this day")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Note Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Note")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        TextField("Enter note...", text: $noteText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.white)
                            .lineLimit(3...6)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Note")
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
                        onSave(noteText)
                        dismiss()
                    }
                    .foregroundColor(.lumoGreen)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
}

// MARK: - Ingredient Chip
struct IngredientChip: View {
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

// MARK: - Leftover Recipe Card
struct LeftoverRecipeCard: View {
    let recipe: Recipe
    let availableIngredients: Set<String>
    let onAddToPlan: () -> Void
    
    private var matchScore: Double {
        let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
        let availableIngredientsLower = availableIngredients.map { $0.lowercased() }
        let matchingIngredients = recipeIngredients.filter { recipeIngredient in
            availableIngredientsLower.contains { availableIngredient in
                availableIngredient.contains(recipeIngredient) || recipeIngredient.contains(availableIngredient)
            }
        }
        return Double(matchingIngredients.count) / Double(recipeIngredients.count)
    }
    
    private var matchCount: Int {
        let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
        let availableIngredientsLower = availableIngredients.map { $0.lowercased() }
        return recipeIngredients.filter { recipeIngredient in
            availableIngredientsLower.contains { availableIngredient in
                availableIngredient.contains(recipeIngredient) || recipeIngredient.contains(availableIngredient)
            }
        }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Uses \(matchCount) of \(recipe.ingredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.lumoGreen)
                }
                
                Spacer()
                
                // Match Score Badge
                ZStack {
                    Circle()
                        .fill(matchScoreColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("\(Int(matchScore * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(matchScoreColor)
                }
            }
            
            Text(recipe.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Text("\(recipe.servings) servings")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("Add to Plan") {
                    onAddToPlan()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lumoGreen)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var matchScoreColor: Color {
        if matchScore >= 0.8 { return .green }
        if matchScore >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Save Template View
struct SaveTemplateView: View {
    let onSave: (MealPlanTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var selectedTags: Set<String> = []
    
    private let availableTags = ["Vegan", "Vegetarian", "Low Carb", "High Protein", "Budget", "Quick", "Family", "Healthy", "Gluten-Free", "Dairy-Free"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Template Info
                        templateInfoSection
                        
                        // Tags Selection
                        tagsSection
                        
                        // Preview
                        previewSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Save Template")
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
                        saveTemplate()
                    }
                    .foregroundColor(.lumoGreen)
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var templateInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Template Information")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                TextField("Template Name", text: $templateName)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.white)
                
                TextField("Description (optional)", text: $templateDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.white)
                    .lineLimit(2...4)
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(availableTags, id: \.self) { tag in
                    TagChip(
                        name: tag,
                        isSelected: selectedTags.contains(tag),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedTags.insert(tag)
                            } else {
                                selectedTags.remove(tag)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            let allMeals = appState.mealPlans.flatMap { $0.meals }
            
            VStack(spacing: 8) {
                ForEach(allMeals.prefix(5), id: \.id) { meal in
                    HStack {
                        Text(meal.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let recipe = meal.recipe {
                            Text(recipe.name)
                                .font(.caption)
                                .foregroundColor(.white)
                        } else if let customMeal = meal.customMeal {
                            Text(customMeal)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if allMeals.count > 5 {
                    Text("+ \(allMeals.count - 5) more meals")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func saveTemplate() {
        let allMeals = appState.mealPlans.flatMap { $0.meals }
        let template = MealPlanTemplate(
            name: templateName,
            description: templateDescription,
            tags: Array(selectedTags),
            meals: allMeals
        )
        onSave(template)
    }
}

// MARK: - Edit Meal View
struct EditMealView: View {
    let meal: MealPlan.Meal
    let onSave: (MealPlan.Meal) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedMeal: MealPlan.Meal
    @State private var selectedRecipe: Recipe?
    @State private var customMeal: String
    @State private var servings: Int
    @State private var showingRecipePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedIngredients: Set<UUID> = []
    
    init(meal: MealPlan.Meal, onSave: @escaping (MealPlan.Meal) -> Void, onDelete: @escaping () -> Void) {
        self.meal = meal
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state with current meal data
        _editedMeal = State(initialValue: meal)
        _selectedRecipe = State(initialValue: meal.recipe)
        _customMeal = State(initialValue: meal.customMeal ?? "")
        _servings = State(initialValue: meal.recipe?.servings ?? 1)
        
        // Initialize selected ingredients
        let initialSelected = Set(meal.ingredients.map { $0.id })
        _selectedIngredients = State(initialValue: initialSelected)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Meal Type Display
                        mealTypeSection
                        
                        // Recipe/Meal Content
                        mealContentSection
                        
                        // Servings Control
                        servingsSection
                        
                        // Ingredients List
                        ingredientsSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Meal")
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
                updateIngredientsFromRecipe(recipe)
            }
        }
        .confirmationDialog(
            "Delete Meal",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this meal?")
        }
    }
    
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Type")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(mealTypeColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mealTypeIcon)
                        .foregroundColor(mealTypeColor)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Tap to change")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var mealContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Content")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let recipe = selectedRecipe {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(recipe.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Replace") {
                                showingRecipePicker = true
                            }
                            .font(.caption)
                            .foregroundColor(.lumoGreen)
                        }
                        
                        Text(recipe.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.lumoGreen.opacity(0.1))
                    .cornerRadius(12)
                } else {
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
        }
    }
    
    private var servingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Servings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Button(action: {
                    if servings > 1 {
                        servings -= 1
                        updateIngredientsForServings()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title2)
                }
                .disabled(servings <= 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(servings)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("servings")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    servings += 1
                    updateIngredientsForServings()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.lumoGreen)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(editedMeal.ingredients, id: \.id) { ingredient in
                    IngredientRow(
                        ingredient: ingredient,
                        isSelected: selectedIngredients.contains(ingredient.id),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedIngredients.insert(ingredient.id)
                            } else {
                                selectedIngredients.remove(ingredient.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Delete Meal") {
                showingDeleteConfirmation = true
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.2))
            .cornerRadius(12)
        }
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
    
    private func updateIngredientsFromRecipe(_ recipe: Recipe) {
        let scaleFactor = Double(servings) / Double(recipe.servings)
        editedMeal.ingredients = recipe.ingredients.map { ingredient in
            GroceryItem(
                name: ingredient.name,
                description: ingredient.notes ?? "",
                price: ingredient.estimatedPrice * scaleFactor,
                category: "Produce",
                aisle: ingredient.aisle,
                brand: ""
            )
        }
        selectedIngredients = Set(editedMeal.ingredients.map { $0.id })
    }
    
    private func updateIngredientsForServings() {
        guard let recipe = selectedRecipe else { return }
        updateIngredientsFromRecipe(recipe)
    }
    
    private func saveMeal() {
        var updatedMeal = editedMeal
        updatedMeal.recipe = selectedRecipe
        updatedMeal.customMeal = selectedRecipe == nil ? customMeal : nil
        updatedMeal.ingredients = editedMeal.ingredients.filter { selectedIngredients.contains($0.id) }
        
        onSave(updatedMeal)
        dismiss()
    }
}

// MARK: - Ingredient Row
struct IngredientRow: View {
    let ingredient: GroceryItem
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onToggle(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .lumoGreen : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(ingredient.price, specifier: "%.2f") • \(ingredient.category)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 