//
//  StoreMapView.swift
//  Lumo
//
//  Interactive store map with route visualization and navigation
//  Shows optimal shopping routes with turn-by-turn directions
//

import SwiftUI

struct StoreMapView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var routeManager = RouteOptimizationManager.shared
    @State private var showingRouteOptions = false
    @State private var selectedOptimization: ShoppingRoute.OptimizationStrategy = .logical
    @State private var isGeneratingRoute = false
    @State private var showingNavigation = false
    @State private var routeGenerated = false
    @State private var showingItemChecklist = false
    @State private var currentUserLocation = Coordinate(x: 2.0, y: 0.0) // Start at entrance
    @State private var showingSuggestions = false
    @State private var routeSuggestions: [RouteSuggestion] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let store = appState.selectedStore,
                   let storeLayout = getStoreLayout(for: store.id) {
                    
                    // Progress Header (when route is active)
                    if routeGenerated, let route = routeManager.currentRoute {
                        RouteProgressHeader(
                            route: route,
                            progress: routeManager.routeProgress,
                            onShowChecklist: { showingItemChecklist = true },
                            onShowSuggestions: { 
                                updateSuggestions(for: storeLayout)
                                showingSuggestions = true 
                            }
                        )
                    }
                    
                    // Map Container with Enhanced Visualization
                    GeometryReader { geometry in
                        EnhancedStoreLayoutMapView(
                            storeLayout: storeLayout,
                            route: routeManager.currentRoute,
                            routeProgress: routeManager.routeProgress,
                            userLocation: currentUserLocation,
                            mapSize: geometry.size,
                            onLocationUpdate: updateUserLocation
                        )
                    }
                    
                    // Real-time Navigation Controls
                    if routeGenerated {
                        RealTimeNavigationControls(
                            route: routeManager.currentRoute,
                            progress: routeManager.routeProgress,
                            onCompleteItem: completeItem,
                            onSkipWaypoint: skipWaypoint,
                            onReoptimize: reoptimizeRoute
                        )
                    } else {
                        // Initial Route Controls
                        RouteControlsView(
                            store: store,
                            isGeneratingRoute: $isGeneratingRoute,
                            showingRouteOptions: $showingRouteOptions,
                            showingNavigation: $showingNavigation,
                            routeGenerated: $routeGenerated,
                            selectedOptimization: $selectedOptimization
                        )
                    }
                    
                } else {
                    StoreSelectionPromptView()
                }
            }
            .navigationTitle("Store Map")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRouteOptions) {
                RouteOptionsSheet(
                    selectedOptimization: $selectedOptimization,
                    onGenerateRoute: generateRoute
                )
            }
            .sheet(isPresented: $showingNavigation) {
                NavigationView {
                    if let route = routeManager.currentRoute {
                        TurnByTurnNavigationView(route: route)
                    }
                }
            }
            .sheet(isPresented: $showingItemChecklist) {
                ItemChecklistSheet(
                    groceryList: appState.groceryList,
                    route: routeManager.currentRoute,
                    progress: routeManager.routeProgress,
                    onCompleteItem: completeItem
                )
            }
            .sheet(isPresented: $showingSuggestions) {
                RouteSuggestionsSheet(
                    suggestions: routeSuggestions,
                    onAcceptSuggestion: acceptSuggestion
                )
            }
        }
    }
    
    // MARK: - Enhanced Route Functions
    
    private func generateRoute() {
        guard let store = appState.selectedStore,
              !appState.groceryList.groceryItems.isEmpty else { return }
        
        let groceryList = appState.groceryList
        
        isGeneratingRoute = true
        
        Task {
            do {
                let route = try await routeManager.generateRoute(
                    for: groceryList,
                    in: store,
                    optimizationStrategy: selectedOptimization
                )
                
                await MainActor.run {
                    routeGenerated = true
                    isGeneratingRoute = false
                    showingRouteOptions = false
                    
                    // Start route progress tracking
                    if let firstWaypoint = route.waypoints.first {
                        routeManager.routeProgress.currentWaypoint = firstWaypoint
                    }
                    
                    // Generate initial suggestions
                    if let storeLayout = getStoreLayout(for: store.id) {
                        updateSuggestions(for: storeLayout)
                    }
                }
            } catch {
                await MainActor.run {
                    isGeneratingRoute = false
                }
            }
        }
    }
    
    private func completeItem(_ itemId: UUID) {
        routeManager.updateRouteProgress(completedItemId: itemId)
        
        // Update user's grocery list to mark item as completed
        if let itemIndex = appState.groceryList.groceryItems.firstIndex(where: { $0.item.id == itemId }) {
            appState.groceryList.groceryItems[itemIndex].isCompleted = true
        }
        
        // Check if route is completed
        if routeManager.routeProgress.isCompleted {
            showRouteCompletedAlert()
        }
    }
    
    private func skipWaypoint(_ waypointId: UUID) {
        routeManager.skipWaypoint(waypointId)
    }
    
    private func reoptimizeRoute() {
        // Get remaining uncompleted items
        let remainingItems = appState.groceryList.groceryItems
            .filter { !$0.isCompleted }
            .map { $0.item.id }
        
        routeManager.reorderRoute(newItemOrder: remainingItems)
    }
    
    private func updateUserLocation(_ location: Coordinate) {
        currentUserLocation = location
        
        // Update suggestions based on new location
        if let store = appState.selectedStore,
           let storeLayout = getStoreLayout(for: store.id) {
            updateSuggestions(for: storeLayout)
        }
    }
    
    private func updateSuggestions(for storeLayout: StoreLayout) {
        routeSuggestions = routeManager.getSuggestions(
            for: currentUserLocation,
            storeLayout: storeLayout
        )
    }
    
    private func acceptSuggestion(_ suggestion: RouteSuggestion) {
        switch suggestion.type {
        case .reoptimize:
            reoptimizeRoute()
        case .nearbyItems:
            // Navigate to suggested aisle
            if let aisleId = suggestion.aisleId,
               let aisle = getStoreLayout(for: appState.selectedStore!.id)?.aisles.first(where: { $0.aisleId == aisleId }) {
                currentUserLocation = aisle.centerPoint
            }
        case .shortcut:
            // Implement shortcut logic
            break
        case .timeAlert:
            // Show time-based alert
            break
        }
        showingSuggestions = false
    }
    
    private func showRouteCompletedAlert() {
        // Show completion celebration and option to start new route
        // This could be a custom alert or sheet
    }
    
    private func getStoreLayout(for storeId: UUID) -> StoreLayout? {
        return sampleStoreLayouts.first { $0.storeId == storeId }
    }
}

// MARK: - Enhanced UI Components

struct RouteProgressHeader: View {
    let route: ShoppingRoute
    let progress: RouteProgress
    let onShowChecklist: () -> Void
    let onShowSuggestions: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(progress.completedWaypoints.count) of \(route.waypoints.count) stops completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Items", action: onShowChecklist)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Button("Tips", action: onShowSuggestions)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress.progressPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("⏱️ \(progress.estimatedTimeRemaining) min remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("📍 \(Int(progress.remainingDistance))ft to go")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EnhancedStoreLayoutMapView: View {
    let storeLayout: StoreLayout
    let route: ShoppingRoute?
    let routeProgress: RouteProgress?
    let userLocation: Coordinate
    let mapSize: CGSize
    let onLocationUpdate: (Coordinate) -> Void
    
    private var scale: CGFloat {
        let scaleX = mapSize.width / storeLayout.mapDimensions.width
        let scaleY = mapSize.height / storeLayout.mapDimensions.height
        return min(scaleX, scaleY) * 0.9
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            // Map Content
            ZStack {
                // Store Boundary
                Rectangle()
                    .stroke(Color.primary, lineWidth: 2)
                    .frame(
                        width: storeLayout.mapDimensions.width * scale,
                        height: storeLayout.mapDimensions.height * scale
                    )
                
                // Aisles with Enhanced States
                ForEach(storeLayout.aisles, id: \.id) { aisle in
                    EnhancedAisleView(
                        aisle: aisle,
                        scale: scale,
                        isOnRoute: route?.waypoints.contains { $0.aisleId == aisle.aisleId } ?? false,
                        isCompleted: routeProgress?.completedWaypoints.contains { waypoint in
                            route?.waypoints.first { $0.aisleId == aisle.aisleId }?.id == waypoint
                        } ?? false,
                        isCurrent: routeProgress?.currentWaypoint?.aisleId == aisle.aisleId,
                        isNearUser: isAisleNearUser(aisle)
                    )
                }
                
                // Enhanced Route Path with Animation
                if let route = route {
                    EnhancedRoutePathView(
                        route: route,
                        storeLayout: storeLayout,
                        scale: scale,
                        progress: routeProgress
                    )
                }
                
                // User Location Indicator
                UserLocationIndicator(location: userLocation, scale: scale)
                    .onTapGesture {
                        // Allow user to manually update their location
                        onLocationUpdate(userLocation)
                    }
                
                // Entrance
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .position(
                        x: storeLayout.entrance.x * scale,
                        y: storeLayout.entrance.y * scale
                    )
                    .overlay(
                        Text("IN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .position(
                                x: storeLayout.entrance.x * scale,
                                y: storeLayout.entrance.y * scale
                            )
                    )
                
                // Checkouts
                ForEach(storeLayout.checkouts, id: \.id) { checkout in
                    CheckoutView(checkout: checkout, scale: scale)
                }
                
                // Interactive Waypoint Markers
                if let route = route {
                    ForEach(route.waypoints, id: \.id) { waypoint in
                        InteractiveWaypointView(
                            waypoint: waypoint,
                            scale: scale,
                            isCompleted: routeProgress?.completedWaypoints.contains(waypoint.id) ?? false,
                            isCurrent: routeProgress?.currentWaypoint?.id == waypoint.id,
                            onTap: { onLocationUpdate(waypoint.position) }
                        )
                    }
                }
            }
            .clipped()
        }
        .padding()
    }
    
    private func isAisleNearUser(_ aisle: Aisle) -> Bool {
        let distance = sqrt(pow(aisle.centerPoint.x - userLocation.x, 2) + pow(aisle.centerPoint.y - userLocation.y, 2))
        return distance < 10.0 // Within 10 units
    }
}

struct UserLocationIndicator: View {
    let location: Coordinate
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Pulsing circle effect
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 24, height: 24)
                .scaleEffect(1.5)
                .animation(.easeInOut(duration: 1.5).repeatForever(), value: location)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .position(x: location.x * scale, y: location.y * scale)
    }
}

struct RealTimeNavigationControls: View {
    let route: ShoppingRoute?
    let progress: RouteProgress?
    let onCompleteItem: (UUID) -> Void
    let onSkipWaypoint: (UUID) -> Void
    let onReoptimize: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let currentWaypoint = progress?.currentWaypoint {
                // Current Stop Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current Stop: \(currentWaypoint.instruction)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(currentWaypoint.estimatedTimeMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !currentWaypoint.products.isEmpty {
                        Text("Items to collect: \(currentWaypoint.products.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Skip Stop") {
                        onSkipWaypoint(currentWaypoint.id)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Reoptimize Route") {
                        onReoptimize()
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Text("Route completed! 🎉")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .padding()
    }
}

struct ItemChecklistSheet: View {
    let groceryList: GroceryList
    let route: ShoppingRoute?
    let progress: RouteProgress?
    let onCompleteItem: (UUID) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let currentWaypoint = progress?.currentWaypoint,
                   !currentWaypoint.products.isEmpty {
                    Section("Current Stop Items") {
                        ForEach(currentWaypoint.products, id: \.self) { productId in
                            if let groceryItem = groceryList.groceryItems.first(where: { $0.item.id == productId }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(groceryItem.item.name)
                                            .font(.body)
                                        Text("Quantity: \(groceryItem.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(groceryItem.isCompleted ? "✅" : "⭕") {
                                        onCompleteItem(productId)
                                    }
                                    .font(.title2)
                                }
                            }
                        }
                    }
                }
                
                Section("All Items") {
                    ForEach(groceryList.groceryItems, id: \.item.id) { groceryItem in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(groceryItem.item.name)
                                    .font(.body)
                                    .strikethrough(groceryItem.isCompleted)
                                Text("Quantity: \(groceryItem.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(groceryItem.isCompleted ? "✅" : "⭕") {
                                onCompleteItem(groceryItem.item.id)
                            }
                            .font(.title2)
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RouteSuggestionsSheet: View {
    let suggestions: [RouteSuggestion]
    let onAcceptSuggestion: (RouteSuggestion) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(suggestions) { suggestion in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(suggestion.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Accept") {
                            onAcceptSuggestion(suggestion)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text(suggestion.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Route Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Enhanced Visual Components

struct EnhancedAisleView: View {
    let aisle: Aisle
    let scale: CGFloat
    let isOnRoute: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let isNearUser: Bool
    
    var body: some View {
        let bounds = aisle.bounds
        let path = Path { path in
            guard !bounds.isEmpty else { return }
            
            path.move(to: CGPoint(x: bounds[0].x * scale, y: bounds[0].y * scale))
            for i in 1..<bounds.count {
                path.addLine(to: CGPoint(x: bounds[i].x * scale, y: bounds[i].y * scale))
            }
            path.closeSubpath()
        }
        
        return path
            .fill(aisleColor)
            .overlay(path.stroke(aisleStrokeColor, lineWidth: strokeWidth))
            .overlay(
                Text(aisle.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .position(x: aisle.centerPoint.x * scale, y: aisle.centerPoint.y * scale)
            )
            .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
    
    private var aisleColor: Color {
        if isCompleted {
            return Color.green.opacity(0.3)
        } else if isCurrent {
            return Color.blue.opacity(0.4)
        } else if isOnRoute {
            return Color.orange.opacity(0.2)
        } else if isNearUser {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var aisleStrokeColor: Color {
        if isCurrent {
            return Color.blue
        } else if isOnRoute {
            return Color.orange
        } else {
            return Color.gray
        }
    }
    
    private var strokeWidth: CGFloat {
        isCurrent ? 3 : (isOnRoute ? 2 : 1)
    }
}

struct EnhancedRoutePathView: View {
    let route: ShoppingRoute
    let storeLayout: StoreLayout
    let scale: CGFloat
    let progress: RouteProgress?
    
    var body: some View {
        ForEach(Array(route.waypoints.enumerated()), id: \.element.id) { index, waypoint in
            if index < route.waypoints.count - 1 {
                let nextWaypoint = route.waypoints[index + 1]
                RouteSegmentView(
                    from: waypoint.position,
                    to: nextWaypoint.position,
                    scale: scale,
                    isCompleted: progress?.completedWaypoints.contains(waypoint.id) ?? false,
                    isCurrent: progress?.currentWaypoint?.id == waypoint.id
                )
            }
        }
    }
}

struct RouteSegmentView: View {
    let from: Coordinate
    let to: Coordinate
    let scale: CGFloat
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: from.x * scale, y: from.y * scale))
            path.addLine(to: CGPoint(x: to.x * scale, y: to.y * scale))
        }
        .stroke(
            isCompleted ? Color.green : (isCurrent ? Color.blue : Color.orange),
            style: StrokeStyle(
                lineWidth: isCurrent ? 4 : 2,
                lineCap: .round,
                dash: isCompleted ? [] : [5, 3]
            )
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
}

struct InteractiveWaypointView: View {
    let waypoint: RouteWaypoint
    let scale: CGFloat
    let isCompleted: Bool
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(waypointColor)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Text("\(waypoint.order)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .position(x: waypoint.position.x * scale, y: waypoint.position.y * scale)
        .scaleEffect(isCurrent ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isCurrent)
    }
    
    private var waypointColor: Color {
        if isCompleted {
            return Color.green
        } else if isCurrent {
            return Color.blue
        } else {
            return Color.orange
        }
    }
    
    private var circleSize: CGFloat {
        isCurrent ? 20 : 16
    }
}

// MARK: - Aisle View

struct AisleView: View {
    let aisle: Aisle
    let scale: CGFloat
    let isOnRoute: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    
    var aisleColor: Color {
        if isCurrent {
            return .blue
        } else if isCompleted {
            return .green
        } else if isOnRoute {
            return .orange
        } else {
            return Color(.systemGray3)
        }
    }
    
    var body: some View {
        ZStack {
            // Aisle bounds
            if aisle.bounds.count >= 4 {
                Path { path in
                    let firstPoint = aisle.bounds[0]
                    path.move(to: CGPoint(
                        x: firstPoint.x * scale,
                        y: firstPoint.y * scale
                    ))
                    
                    for point in aisle.bounds.dropFirst() {
                        path.addLine(to: CGPoint(
                            x: point.x * scale,
                            y: point.y * scale
                        ))
                    }
                    path.closeSubpath()
                }
                .fill(aisleColor.opacity(0.3))
                .stroke(aisleColor, lineWidth: 2)
            }
            
            // Aisle label
            Text(aisle.aisleId)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .position(
                    x: aisle.centerPoint.x * scale,
                    y: aisle.centerPoint.y * scale
                )
        }
    }
}

// MARK: - Checkout View

struct CheckoutView: View {
    let checkout: CheckoutLocation
    let scale: CGFloat
    
    var checkoutColor: Color {
        switch checkout.type {
        case .express: return .blue
        case .selfService: return .purple
        case .pharmacy: return .red
        case .regular: return .gray
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(checkoutColor)
            .frame(width: 8 * scale, height: 4 * scale)
            .position(
                x: checkout.position.x * scale,
                y: checkout.position.y * scale
            )
            .overlay(
                Text(checkout.type.rawValue.prefix(3))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .position(
                        x: checkout.position.x * scale,
                        y: checkout.position.y * scale
                    )
            )
    }
}

// MARK: - Route Path View

struct RoutePathView: View {
    let route: ShoppingRoute
    let storeLayout: StoreLayout
    let scale: CGFloat
    
    var body: some View {
        Path { path in
            // Start from entrance
            let startPoint = CGPoint(
                x: route.startPoint.x * scale,
                y: route.startPoint.y * scale
            )
            path.move(to: startPoint)
            
            // Connect waypoints in order
            for waypoint in route.waypoints.sorted(by: { $0.order < $1.order }) {
                let waypointPoint = CGPoint(
                    x: waypoint.position.x * scale,
                    y: waypoint.position.y * scale
                )
                path.addLine(to: waypointPoint)
            }
            
            // End at checkout
            let endPoint = CGPoint(
                x: route.endPoint.x * scale,
                y: route.endPoint.y * scale
            )
            path.addLine(to: endPoint)
        }
        .stroke(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: .blue.opacity(0.3), radius: 2)
    }
}

// MARK: - Waypoint Marker

struct WaypointMarkerView: View {
    let waypoint: RouteWaypoint
    let scale: CGFloat
    let isCompleted: Bool
    let isCurrent: Bool
    
    var markerColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .orange
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(markerColor)
                .frame(width: 24, height: 24)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text("\(waypoint.order)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .position(
            x: waypoint.position.x * scale,
            y: waypoint.position.y * scale
        )
    }
}

// MARK: - Route Controls

struct RouteControlsView: View {
    let store: Store
    @Binding var isGeneratingRoute: Bool
    @Binding var showingRouteOptions: Bool
    @Binding var showingNavigation: Bool
    @Binding var routeGenerated: Bool
    @Binding var selectedOptimization: ShoppingRoute.OptimizationStrategy
    
    @EnvironmentObject var appState: AppState
    @StateObject private var routeManager = RouteOptimizationManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Route Status
            if let route = routeManager.currentRoute {
                RouteStatsView(route: route)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                if routeGenerated {
                    Button(action: { showingNavigation = true }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Start Navigation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { 
                        routeManager.currentRoute = nil
                        routeGenerated = false
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Clear Route")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: { showingRouteOptions = true }) {
                        HStack {
                            if isGeneratingRoute {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "map")
                            }
                            Text(isGeneratingRoute ? "Generating..." : "Map Route")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            isGeneratingRoute ? Color.gray : Color.blue
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isGeneratingRoute || appState.groceryList.groceryItems.isEmpty)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }
}

// MARK: - Route Stats

struct RouteStatsView: View {
    let route: ShoppingRoute
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0fm", route.totalDistance))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack {
                Text("Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f min", route.estimatedTime))
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack {
                Text("Stops")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(route.waypoints.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack {
                Text("Strategy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(route.optimizationStrategy.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Route Options Sheet

struct RouteOptionsSheet: View {
    @Binding var selectedOptimization: ShoppingRoute.OptimizationStrategy
    let onGenerateRoute: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Route Optimization")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    ForEach(ShoppingRoute.OptimizationStrategy.allCases, id: \.self) { strategy in
                        OptimizationOptionView(
                            strategy: strategy,
                            isSelected: selectedOptimization == strategy,
                            onSelect: { selectedOptimization = strategy }
                        )
                    }
                }
                
                Spacer()
                
                Button("Generate Route") {
                    onGenerateRoute()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("Route Options")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") { dismiss() }
            )
        }
    }
}

struct OptimizationOptionView: View {
    let strategy: ShoppingRoute.OptimizationStrategy
    let isSelected: Bool
    let onSelect: () -> Void
    
    var description: String {
        switch strategy {
        case .shortest:
            return "Minimizes walking distance"
        case .fastest:
            return "Optimizes for speed and efficiency"
        case .logical:
            return "Smart order to keep foods fresh"
        case .custom:
            return "Follow your preferred order"
        }
    }
    
    var icon: String {
        switch strategy {
        case .shortest: return "ruler"
        case .fastest: return "bolt.fill"
        case .logical: return "brain.head.profile"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isSelected ? Color.blue : Color(.systemGray6)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Store Selection Prompt

struct StoreSelectionPromptView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Select a Store")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Choose a store from the Explore tab to view its layout and generate shopping routes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
} 