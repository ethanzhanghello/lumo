//
//  TurnByTurnNavigationView.swift
//  Lumo
//
//  Turn-by-turn navigation interface for grocery shopping routes
//  Provides step-by-step directions and progress tracking
//

import SwiftUI

struct TurnByTurnNavigationView: View {
    let route: ShoppingRoute
    @StateObject private var routeManager = RouteOptimizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var navigationInstructions: [NavigationInstruction] = []
    @State private var showingProductList = false
    @State private var completedItems: Set<UUID> = []
    @State private var showingRouteCompleted = false
    @State private var currentUserLocation = Coordinate(x: 2.0, y: 0.0)
    @State private var navigationStartTime = Date()
    @State private var showingRecalculateAlert = false
    @State private var showingEndNavigationAlert = false
    
    var currentStep: NavigationInstruction? {
        guard let progress = routeManager.routeProgress else { return navigationInstructions.first }
        
        let currentStepIndex = min(progress.currentWaypointIndex + 1, navigationInstructions.count - 1)
        return navigationInstructions.indices.contains(currentStepIndex) ? navigationInstructions[currentStepIndex] : nil
    }
    
    var nextStep: NavigationInstruction? {
        guard let current = currentStep,
              let currentIndex = navigationInstructions.firstIndex(where: { $0.id == current.id }),
              currentIndex + 1 < navigationInstructions.count else { return nil }
        return navigationInstructions[currentIndex + 1]
    }
    
    var timeElapsed: TimeInterval {
        Date().timeIntervalSince(navigationStartTime)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Progress Header with Real-time Stats
                EnhancedRouteProgressHeader(
                    route: route,
                    progress: routeManager.routeProgress,
                    timeElapsed: timeElapsed,
                    estimatedTimeRemaining: routeManager.routeProgress?.estimatedTimeRemaining ?? 0
                )
                
                // Current Step Card with Voice Guidance
                if let currentStep = currentStep {
                    EnhancedCurrentStepCard(
                        instruction: currentStep,
                        nextInstruction: nextStep,
                        userLocation: currentUserLocation,
                        onShowProducts: { showingProductList = true },
                        onMarkCompleted: { markStepCompleted(currentStep) },
                        onSkipStep: { skipCurrentStep() }
                    )
                }
                
                // Real-time Instruction List with Progress
                EnhancedNavigationInstructionsList(
                    instructions: navigationInstructions,
                    currentStep: currentStep,
                    routeProgress: routeManager.routeProgress,
                    completedItems: completedItems,
                    onMarkCompleted: markWaypointCompleted,
                    onItemCompleted: markItemCompleted
                )
                
                Spacer()
                
                // Enhanced Control Buttons
                EnhancedNavigationControlsView(
                    onEndNavigation: { showingEndNavigationAlert = true },
                    onRecalculateRoute: { showingRecalculateAlert = true },
                    onCurrentLocation: updateUserLocation,
                    isNavigationActive: routeManager.routeProgress != nil
                )
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("End") { showingEndNavigationAlert = true }
            )
            .onAppear {
                startNavigation()
            }
            .sheet(isPresented: $showingProductList) {
                if let currentStep = currentStep {
                    EnhancedProductListSheet(
                        aisleId: currentStep.aisleTarget ?? "",
                        route: route,
                        completedItems: $completedItems,
                        onItemCompleted: markItemCompleted
                    )
                }
            }
            .alert("Route Completed! 🎉", isPresented: $showingRouteCompleted) {
                Button("View Summary") { showRouteSummary() }
                Button("Done") { endNavigation() }
            } message: {
                Text("Congratulations! You've completed your shopping route.")
            }
            .alert("End Navigation?", isPresented: $showingEndNavigationAlert) {
                Button("End", role: .destructive) { endNavigation() }
                Button("Continue") { }
            } message: {
                Text("Are you sure you want to end navigation? Your progress will be saved.")
            }
            .alert("Recalculate Route?", isPresented: $showingRecalculateAlert) {
                Button("Recalculate") { recalculateRoute() }
                Button("Cancel") { }
            } message: {
                Text("This will optimize your route based on remaining items and current location.")
            }
        }
    }
    
    // MARK: - Enhanced Navigation Functions
    
    private func startNavigation() {
        navigationInstructions = routeManager.generateTurnByTurnDirections(for: route)
        routeManager.startRouteNavigation(route)
        navigationStartTime = Date()
        
        // Initialize user location at store entrance
        if let storeLayout = getStoreLayout() {
            currentUserLocation = storeLayout.entrance
        }
    }
    
    private func markWaypointCompleted(_ waypointId: UUID) {
        routeManager.markWaypointCompleted(waypointId)
        checkForRouteCompletion()
    }
    
    private func markStepCompleted(_ step: NavigationInstruction) {
        // Mark all products in this step as completed
        if let aisleId = step.aisleTarget,
           let waypoint = route.waypoints.first(where: { $0.aisleId == aisleId }) {
            for productId in waypoint.products {
                completedItems.insert(productId)
                routeManager.updateRouteProgress(completedItemId: productId)
            }
        }
        checkForRouteCompletion()
    }
    
    private func markItemCompleted(_ itemId: UUID) {
        completedItems.insert(itemId)
        routeManager.updateRouteProgress(completedItemId: itemId)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        checkForRouteCompletion()
    }
    
    private func skipCurrentStep() {
        guard let currentStep = currentStep,
              let waypoint = route.waypoints.first(where: { $0.aisleId == currentStep.aisleTarget }) else { return }
        
        routeManager.skipWaypoint(waypoint.id)
    }
    
    private func checkForRouteCompletion() {
        if routeManager.routeProgress?.isCompleted == true {
            showingRouteCompleted = true
        }
    }
    
    private func updateUserLocation() {
        // In a real implementation, this would use indoor positioning
        // For now, simulate movement to current waypoint
        if let currentWaypoint = routeManager.routeProgress?.currentWaypoint {
            currentUserLocation = currentWaypoint.position
        }
    }
    
    private func endNavigation() {
        // Save navigation session for analytics
        saveNavigationSession()
        routeManager.routeProgress = nil
        dismiss()
    }
    
    private func recalculateRoute() {
        Task {
            do {
                // Get remaining items
                let remainingItems = route.waypoints
                    .flatMap { $0.products }
                    .filter { !completedItems.contains($0) }
                
                if !remainingItems.isEmpty {
                    routeManager.reorderRoute(newItemOrder: remainingItems)
                    
                    // Regenerate instructions
                    navigationInstructions = routeManager.generateTurnByTurnDirections(for: route)
                }
            }
        }
    }
    
    private func showRouteSummary() {
        // Show completion summary with stats
        // This could be another sheet or navigation destination
    }
    
    private func saveNavigationSession() {
        // Save session data for analytics and improvements
        let session = NavigationSession(
            routeId: route.id,
            startTime: navigationStartTime,
            endTime: Date(),
            completedItems: completedItems,
            totalItems: route.waypoints.flatMap { $0.products }.count,
            actualTimeMinutes: Int(timeElapsed / 60)
        )
        
        // Save to persistent storage or analytics service
        print("Navigation session completed: \(session)")
    }
    
    private func getStoreLayout() -> StoreLayout? {
        return sampleStoreLayouts.first { $0.storeId == route.storeId }
    }
}

// MARK: - Enhanced UI Components

struct EnhancedRouteProgressHeader: View {
    let route: ShoppingRoute
    let progress: RouteProgress?
    let timeElapsed: TimeInterval
    let estimatedTimeRemaining: Int
    
    var completionPercentage: Double {
        progress?.progressPercentage ?? 0.0
    }
    
    var completedWaypoints: Int {
        progress?.completedWaypoints.count ?? 0
    }
    
    var totalWaypoints: Int {
        route.waypoints.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Enhanced Progress Bar with Animation
            VStack(spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(completedWaypoints)/\(totalWaypoints) stops")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .animation(.easeInOut(duration: 0.5), value: completionPercentage)
            }
            
            // Real-time Stats Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Elapsed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(timeElapsed))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(estimatedTimeRemaining) min")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Navigation Session Model

struct NavigationSession {
    let routeId: UUID
    let startTime: Date
    let endTime: Date
    let completedItems: Set<UUID>
    let totalItems: Int
    let actualTimeMinutes: Int
}

// MARK: - Current Step Card

struct CurrentStepCard: View {
    let instruction: NavigationInstruction
    let nextInstruction: NavigationInstruction?
    let onShowProducts: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Instruction
            HStack {
                // Direction Icon
                Image(systemName: instruction.direction.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(instruction.step)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(instruction.instruction)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    
                    if instruction.distance > 0 {
                        Text(String(format: "%.0fm", instruction.distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Products Button (if applicable)
            if let aisleTarget = instruction.aisleTarget, aisleTarget != "CHECKOUT" {
                Button(action: onShowProducts) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("View Items")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            
            // Next Step Preview
            if let nextInstruction = nextInstruction {
                Divider()
                
                HStack {
                    Text("Next:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: nextInstruction.direction.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(nextInstruction.instruction)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Instructions List

struct NavigationInstructionsList: View {
    let instructions: [NavigationInstruction]
    let currentStep: NavigationInstruction?
    let routeProgress: RouteProgress?
    let onMarkCompleted: (UUID) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(instructions, id: \.id) { instruction in
                    NavigationInstructionRow(
                        instruction: instruction,
                        isCurrent: currentStep?.id == instruction.id,
                        isCompleted: isInstructionCompleted(instruction),
                        onMarkCompleted: onMarkCompleted
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func isInstructionCompleted(_ instruction: NavigationInstruction) -> Bool {
        guard let progress = routeProgress,
              let aisleTarget = instruction.aisleTarget,
              let waypoint = progress.route.waypoints.first(where: { $0.aisleId == aisleTarget }) else {
            return false
        }
        return progress.visitedWaypoints.contains(waypoint.id)
    }
}

struct NavigationInstructionRow: View {
    let instruction: NavigationInstruction
    let isCurrent: Bool
    let isCompleted: Bool
    let onMarkCompleted: (UUID) -> Void
    
    var body: some View {
        HStack {
            // Step Number / Status
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(instruction.step)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isCurrent ? .white : .gray)
                }
            }
            
            // Direction Icon
            Image(systemName: instruction.direction.icon)
                .font(.subheadline)
                .foregroundColor(instructionColor)
                .frame(width: 24)
            
            // Instruction Text
            VStack(alignment: .leading, spacing: 2) {
                Text(instruction.instruction)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(instructionColor)
                
                if instruction.distance > 0 {
                    Text(String(format: "%.0fm", instruction.distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Complete Button
            if isCurrent && !isCompleted && instruction.aisleTarget != "CHECKOUT" {
                Button("Done") {
                    if instruction.aisleTarget != nil {
                        // Find waypoint for this aisle
                        // This is simplified - in a real app you'd properly match waypoints
                        onMarkCompleted(UUID()) // Placeholder
                    }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isCurrent ? Color.blue.opacity(0.1) : Color.clear
        )
        .cornerRadius(8)
    }
    
    private var circleColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var instructionColor: Color {
        if isCompleted {
            return .secondary
        } else if isCurrent {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - Product List Sheet

struct ProductListSheet: View {
    let aisleId: String
    let route: ShoppingRoute
    @Binding var completedItems: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    
    var productsInAisle: [UUID] {
        route.waypoints.first { $0.aisleId == aisleId }?.products ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !productsInAisle.isEmpty {
                    List {
                        ForEach(productsInAisle, id: \.self) { productId in
                            ProductItemRow(
                                productId: productId,
                                isCompleted: completedItems.contains(productId),
                                onToggle: { toggleItem(productId) }
                            )
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No items in this aisle")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Items in \(aisleId)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") { dismiss() }
            )
        }
    }
    
    private func toggleItem(_ productId: UUID) {
        if completedItems.contains(productId) {
            completedItems.remove(productId)
        } else {
            completedItems.insert(productId)
        }
    }
}

struct ProductItemRow: View {
    let productId: UUID
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var product: GroceryItem? {
        sampleGroceryItems.first { $0.id == productId }
    }
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            if let product = product {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(isCompleted)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            } else {
                Text("Unknown Product")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Navigation Controls

struct NavigationControlsView: View {
    let onEndNavigation: () -> Void
    let onRecalculateRoute: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button("Recalculate") {
                onRecalculateRoute()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button("End Navigation") {
                onEndNavigation()
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
} 