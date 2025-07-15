//
//  MealPlanningView.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import SwiftUI

struct MealPlanningView: View {
    @StateObject private var mealManager = MealPlanManager.shared
    @State private var selectedWeekStart = Date().startOfWeek()
    @State private var showingAddMeal = false
    @State private var showingAutoFill = false
    @State private var showingNutritionAnalysis = false
    @State private var showingGroceryList = false
    @State private var showingMealToDelete: Meal?
    @State private var showingDeleteConfirmation = false
    @State private var showingEditMeal = false
    @State private var mealToEdit: Meal?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with week navigation
                    weekNavigationHeader
                    
                    // Enhanced meal planning content
                    mealPlanningContent
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
        }
        .navigationTitle("Meal Planning")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(selectedDate: Date(), selectedMealType: .dinner)
        }
        .sheet(isPresented: $showingAutoFill) {
            AutoFillView()
        }
        .sheet(isPresented: $showingNutritionAnalysis) {
            NutritionAnalysisView()
        }
        .sheet(isPresented: $showingGroceryList) {
            GeneratedGroceryListView()
        }
        .sheet(isPresented: $showingEditMeal) {
            if let meal = mealToEdit {
                EditMealView(meal: meal) { updatedMeal in
                    mealManager.updateMeal(updatedMeal)
                    showingEditMeal = false
                    mealToEdit = nil
                }
            }
        }
        .alert("Delete Meal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                showingMealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = showingMealToDelete {
                    deleteMeal(meal)
                }
                showingMealToDelete = nil
            }
        } message: {
            if let meal = showingMealToDelete {
                Text("Are you sure you want to delete \(meal.recipeName) from your meal plan?")
            }
        }
    }
    
    // MARK: - Enhanced UI Components
    
    private var weekNavigationHeader: some View {
        VStack(spacing: 16) {
            // Week selector
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.lumoGreen)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(weekRangeText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Week of \(weekYearText)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.lumoGreen)
                }
            }
            
            // Quick stats
            weekStatsView
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var weekStatsView: some View {
        HStack(spacing: 16) {
            StatChip(
                icon: "calendar",
                value: "\(totalMealsThisWeek)",
                label: "Meals"
            )
            
            StatChip(
                icon: "person.2",
                value: "\(averageServingsThisWeek)",
                label: "Avg Servings"
            )
            
            StatChip(
                icon: "clock",
                value: "\(totalCookTimeThisWeek)m",
                label: "Cook Time"
            )
        }
    }
    
    private var mealPlanningContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(weekDays, id: \.self) { date in
                DayMealPlanCard(
                    date: date,
                    meals: mealManager.meals(for: date),
                    onEditMeal: { meal in
                        editMeal(meal)
                    },
                    onDeleteMeal: { meal in
                        requestDeleteMeal(meal)
                    }
                )
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(
                    title: "Add Meal",
                    icon: "plus.circle.fill",
                    color: .lumoGreen
                ) {
                    showingAddMeal = true
                }
                
                ActionButton(
                    title: "Auto Fill",
                    icon: "wand.and.stars",
                    color: .blue
                ) {
                    showingAutoFill = true
                }
            }
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Nutrition",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                ) {
                    showingNutritionAnalysis = true
                }
                
                ActionButton(
                    title: "Grocery List",
                    icon: "cart.badge.plus",
                    color: .purple
                ) {
                    showingGroceryList = true
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var weekDays: [Date] {
        (0..<7).compactMap { dayOffset in
            Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedWeekStart)
        }
    }
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startText = formatter.string(from: selectedWeekStart)
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart) ?? selectedWeekStart
        let endText = formatter.string(from: endDate)
        
        return "\(startText) - \(endText)"
    }
    
    private var weekYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedWeekStart)
    }
    
    private var totalMealsThisWeek: Int {
        weekDays.reduce(0) { total, date in
            total + mealManager.meals(for: date).count
        }
    }
    
    private var averageServingsThisWeek: Int {
        let totalServings = weekDays.reduce(0) { total, date in
            total + mealManager.meals(for: date).reduce(0) { dayTotal, meal in
                dayTotal + meal.servings
            }
        }
        return totalMealsThisWeek > 0 ? totalServings / totalMealsThisWeek : 0
    }
    
    private var totalCookTimeThisWeek: Int {
        weekDays.reduce(0) { total, date in
            total + mealManager.meals(for: date).reduce(0) { dayTotal, meal in
                dayTotal + (meal.recipe?.totalTime ?? 30)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func changeWeek(by offset: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedWeekStart) ?? selectedWeekStart
        }
    }
    
    private func editMeal(_ meal: Meal) {
        mealToEdit = meal
        showingEditMeal = true
    }
    
    private func requestDeleteMeal(_ meal: Meal) {
        showingMealToDelete = meal
        showingDeleteConfirmation = true
    }
    
    private func deleteMeal(_ meal: Meal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            mealManager.removeMeal(meal)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Enhanced Supporting Views

struct DayMealPlanCard: View {
    let date: Date
    let meals: [Meal]
    let onEditMeal: (Meal) -> Void
    let onDeleteMeal: (Meal) -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayFormatter.string(from: date))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if meals.isEmpty {
                    Text("No meals planned")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("\(meals.count) meal\(meals.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.lumoGreen)
                }
            }
            
            // Meals for this day
            if meals.isEmpty {
                EmptyMealSlot()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(meals) { meal in
                        EnhancedMealCard(
                            meal: meal,
                            onEdit: { onEditMeal(meal) },
                            onDelete: { onDeleteMeal(meal) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EnhancedMealCard: View {
    let meal: Meal
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal type indicator
            VStack(spacing: 4) {
                Text(meal.type.emoji)
                    .font(.title2)
                
                Text(meal.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 60)
            
            // Meal details
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.recipeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    if let recipe = meal.recipe {
                        Label("\(recipe.totalTime)m", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Label("\(meal.servings) servings", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let recipe = meal.recipe {
                        Label(String(format: "%.1f", recipe.rating), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(meal.type.color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(meal.type.color.opacity(0.3), lineWidth: 1)
        )
        // Enhanced swipe-to-delete functionality
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

struct EmptyMealSlot: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.dotted")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Add a meal")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}

struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.lumoGreen)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - Edit Meal View

struct EditMealView: View {
    @State private var meal: Meal
    let onSave: (Meal) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date
    @State private var selectedMealType: MealType
    @State private var servings: Int
    @State private var notes: String
    
    init(meal: Meal, onSave: @escaping (Meal) -> Void) {
        self._meal = State(initialValue: meal)
        self.onSave = onSave
        self._selectedDate = State(initialValue: meal.date)
        self._selectedMealType = State(initialValue: meal.type)
        self._servings = State(initialValue: meal.servings)
        self._notes = State(initialValue: meal.notes ?? "")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Edit Meal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveMeal()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.lumoGreen)
                }
                .padding()
                .background(Color.black)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Recipe preview
                        recipePreviewSection
                        
                        // Date selection
                        dateSelectionSection
                        
                        // Meal type selection
                        mealTypeSelectionSection
                        
                        // Servings and notes
                        detailsSection
                    }
                    .padding()
                }
            }
        }
    }
    
    private var recipePreviewSection: some View {
        VStack(spacing: 12) {
            Text(meal.recipeName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if let recipe = meal.recipe {
                HStack(spacing: 16) {
                    InfoChip(icon: "clock", text: "\(recipe.totalTime) min")
                    InfoChip(icon: "star.fill", text: String(format: "%.1f", recipe.rating))
                    InfoChip(icon: "dollarsign.circle", text: String(format: "$%.2f", recipe.estimatedCost))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .colorScheme(.dark)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { mealType in
                    MealTypeSelectionCard(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    ) {
                        selectedMealType = mealType
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            // Servings
            VStack(alignment: .leading, spacing: 12) {
                Text("Servings")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Button(action: {
                        if servings > 1 {
                            servings -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(servings > 1 ? .lumoGreen : .gray)
                    }
                    .disabled(servings <= 1)
                    
                    Spacer()
                    
                    Text("\(servings)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        if servings < 12 {
                            servings += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(servings < 12 ? .lumoGreen : .gray)
                    }
                    .disabled(servings >= 12)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Notes
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .colorScheme(.dark)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func saveMeal() {
        var updatedMeal = meal
        updatedMeal.date = selectedDate
        updatedMeal.type = selectedMealType
        updatedMeal.servings = servings
        updatedMeal.notes = notes.isEmpty ? nil : notes
        
        onSave(updatedMeal)
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