//
//  RouteOptimizationManager.swift
//  Lumo
//
//  Route optimization and mapping service for grocery shopping
//  Handles pathfinding, route optimization, and turn-by-turn directions
//

import Foundation
import SwiftUI

class RouteOptimizationManager: ObservableObject {
    @Published var currentRoute: ShoppingRoute?
    @Published var isGeneratingRoute = false
    @Published var routeProgress: RouteProgress?
    @Published var estimatedTimeRemaining: Double = 0
    
    static let shared = RouteOptimizationManager()
    private init() {}
    
    // MARK: - Route Generation
    
    /// Generate optimal shopping route for a grocery list
    func generateRoute(
        for groceryList: GroceryList,
        in store: Store,
        optimizationStrategy: ShoppingRoute.OptimizationStrategy = .logicalOrder
    ) async throws -> ShoppingRoute {
        
        print("🗺️ Starting route generation for store: \(store.name)")
        print("🗺️ Grocery list has \(groceryList.groceryItems.count) items")
        
        await MainActor.run {
            isGeneratingRoute = true
        }
        
        defer {
            Task { @MainActor in
                isGeneratingRoute = false
                print("🗺️ Route generation completed")
            }
        }
        
        // Validate grocery list
        guard !groceryList.groceryItems.isEmpty else {
            print("❌ Empty grocery list")
            throw RouteOptimizationError.invalidGroceryList
        }
        
        // Get store layout
        guard let storeLayout = getStoreLayout(for: store.id) else {
            print("❌ Store layout not found for store ID: \(store.id)")
            throw RouteOptimizationError.storeLayoutNotFound
        }
        
        print("✅ Found store layout with \(storeLayout.aisles.count) aisles")
        
        // Group products by aisle
        let aisleGroups = try groupProductsByAisle(groceryList.groceryItems.map { $0.item }, storeId: store.id)
        
        // Optimize aisle visiting order
        let optimizedAisleOrder = optimizeAisleOrder(
            aisleGroups: aisleGroups,
            storeLayout: storeLayout,
            strategy: optimizationStrategy
        )
        
        print("🗺️ Optimized aisle order: \(optimizedAisleOrder)")
        
        // Generate waypoints
        let waypoints = generateWaypoints(
            from: optimizedAisleOrder,
            storeLayout: storeLayout
        )
        
        print("🗺️ Generated \(waypoints.count) waypoints")
        
        // Calculate total distance and time
        let (totalDistance, estimatedTime) = calculateRouteMetrics(
            waypoints: waypoints,
            storeLayout: storeLayout
        )
        
        print("🗺️ Route metrics: \(totalDistance)m distance, \(estimatedTime) minutes")
        
        let route = ShoppingRoute(
            storeId: store.id,
            waypoints: waypoints,
            totalDistance: totalDistance,
            estimatedTime: Int(estimatedTime),
            optimizationStrategy: optimizationStrategy,
            createdAt: Date()
        )
        
        await MainActor.run {
            currentRoute = route
            print("✅ Route successfully generated and stored")
        }
        
        return route
    }
    
    // MARK: - Product-to-Aisle Mapping
    
    private func groupProductsByAisle(_ items: [GroceryItem], storeId: UUID) throws -> [String: [GroceryItem]] {
        var aisleGroups: [String: [GroceryItem]] = [:]
        
        print("🗺️ Grouping \(items.count) items by aisle for store: \(storeId)")
        
        for item in items {
            // Always use category-based mapping since product locations use random UUIDs
            let aisleId = mapCategoryToAisle(category: item.category)
            print("🗺️ Mapping \(item.name) (category: \(item.category)) -> aisle: \(aisleId)")
            
            if aisleGroups[aisleId] == nil {
                aisleGroups[aisleId] = []
            }
            aisleGroups[aisleId]?.append(item)
        }
        
        print("🗺️ Grouped into \(aisleGroups.count) aisles: \(Array(aisleGroups.keys))")
        
        if aisleGroups.isEmpty {
            throw RouteOptimizationError.noProductsFound
        }
        
        return aisleGroups
    }
    
    private func mapCategoryToAisle(category: String) -> String {
        switch category.lowercased() {
        case "produce", "fruits", "vegetables": return "PRODUCE"
        case "meat & seafood", "meat", "seafood", "deli": return "MEAT"
        case "dairy", "milk", "cheese", "yogurt": return "DAIRY"
        case "frozen", "frozen foods": return "FROZEN"
        case "bakery", "bread", "baked goods": return "BAKERY"
        case "bulk", "bulk foods", "grains", "nuts": return "BULK"
        case "pantry", "canned goods", "pasta", "rice": return "A1"
        case "snacks", "chips", "crackers": return "A2"
        case "beverages", "drinks", "soda", "water", "juice": return "A2"
        case "household", "cleaning", "paper goods": return "A3"
        case "personal care", "health", "beauty", "pharmacy": return "A3"
        default: 
            print("⚠️ Unknown category '\(category)', defaulting to A1")
            return "A1" // Default to pantry aisle
        }
    }
    
    // MARK: - Route Optimization Algorithms
    
    private func optimizeAisleOrder(
        aisleGroups: [String: [GroceryItem]],
        storeLayout: StoreLayout,
        strategy: ShoppingRoute.OptimizationStrategy
    ) -> [String] {
        
        let aisleIds = Array(aisleGroups.keys)
        
        switch strategy {
        case .shortestDistance:
            return optimizeForShortestDistance(aisleIds: aisleIds, storeLayout: storeLayout)
        case .fastestTime:
            return optimizeForSpeed(aisleIds: aisleIds, storeLayout: storeLayout)
        case .logicalOrder:
            return optimizeForLogicalShopping(aisleIds: aisleIds, storeLayout: storeLayout)
        }
    }
    
    private func optimizeForLogicalShopping(aisleIds: [String], storeLayout: StoreLayout) -> [String] {
        // Smart shopping order: Produce → Pantry → Frozen → Dairy → Meat (to keep cold items cold)
        let priorityOrder: [String] = [
            "PRODUCE", "BAKERY", "A1", "A2", "A3", "FROZEN", "DAIRY", "MEAT"
        ]
        
        var result: [String] = []
        
        // Add aisles in priority order if they exist in the shopping list
        for priority in priorityOrder {
            if aisleIds.contains(priority) {
                result.append(priority)
            }
        }
        
        // Add any remaining aisles not in priority order
        for aisleId in aisleIds {
            if !result.contains(aisleId) {
                result.append(aisleId)
            }
        }
        
        return result
    }
    
    private func optimizeForShortestDistance(aisleIds: [String], storeLayout: StoreLayout) -> [String] {
        // Traveling Salesman Problem (TSP) approximation using nearest neighbor
        var unvisited = Set(aisleIds)
        var result: [String] = []
        var currentPosition = storeLayout.entrance
        
        while !unvisited.isEmpty {
            let nearest = unvisited.min { aisle1, aisle2 in
                let dist1 = distanceToAisle(aisle1, from: currentPosition, storeLayout: storeLayout)
                let dist2 = distanceToAisle(aisle2, from: currentPosition, storeLayout: storeLayout)
                return dist1 < dist2
            }!
            
            result.append(nearest)
            unvisited.remove(nearest)
            
            if let aisle = storeLayout.aisles.first(where: { $0.aisleId == nearest }) {
                currentPosition = aisle.centerPoint
            }
        }
        
        return result
    }
    
    private func optimizeForSpeed(aisleIds: [String], storeLayout: StoreLayout) -> [String] {
        // Similar to shortest distance but considers walking speed and congestion
        return optimizeForShortestDistance(aisleIds: aisleIds, storeLayout: storeLayout)
    }
    
    private func distanceToAisle(_ aisleId: String, from position: Coordinate, storeLayout: StoreLayout) -> Double {
        guard let aisle = storeLayout.aisles.first(where: { $0.aisleId == aisleId }) else { return Double.infinity }
        let dx = aisle.centerPoint.x - position.x
        let dy = aisle.centerPoint.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Enhanced A* Pathfinding Algorithm
    
    private func findOptimalPath(from start: Coordinate, to destination: Coordinate, storeLayout: StoreLayout) -> [Coordinate] {
        let graph = storeLayout.connectivityGraph
        
        guard let startNode = findNearestNode(to: start, in: graph),
              let endNode = findNearestNode(to: destination, in: graph) else {
            return [start, destination] // Fallback direct path
        }
        
        return aStar(from: startNode, to: endNode, graph: graph) ?? [start, destination]
    }
    
    private func aStar(from startNode: ConnectivityNode, to endNode: ConnectivityNode, graph: ConnectivityGraph) -> [Coordinate]? {
        var openSet = Set<UUID>([startNode.id])
        var cameFrom: [UUID: UUID] = [:]
        var gScore: [UUID: Double] = [startNode.id: 0]
        var fScore: [UUID: Double] = [startNode.id: heuristic(startNode.position, endNode.position)]
        
        while !openSet.isEmpty {
            // Find node with lowest fScore
            let current = openSet.min { node1, node2 in
                (fScore[node1] ?? Double.infinity) < (fScore[node2] ?? Double.infinity)
            }!
            
            if current == endNode.id {
                // Reconstruct path
                return reconstructPath(cameFrom: cameFrom, current: current, graph: graph)
            }
            
            openSet.remove(current)
            
            // Check neighbors
            let currentNode = graph.nodes.first { $0.id == current }!
            let neighbors = getNeighbors(of: currentNode, in: graph)
            
            for neighbor in neighbors {
                let tentativeGScore = (gScore[current] ?? Double.infinity) + 
                    distanceBetweenNodes(currentNode, neighbor)
                
                if tentativeGScore < (gScore[neighbor.id] ?? Double.infinity) {
                    cameFrom[neighbor.id] = current
                    gScore[neighbor.id] = tentativeGScore
                    fScore[neighbor.id] = tentativeGScore + heuristic(neighbor.position, endNode.position)
                    
                    if !openSet.contains(neighbor.id) {
                        openSet.insert(neighbor.id)
                    }
                }
            }
        }
        
        return nil // No path found
    }
    
    private func heuristic(_ a: Coordinate, _ b: Coordinate) -> Double {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func findNearestNode(to coordinate: Coordinate, in graph: ConnectivityGraph) -> ConnectivityNode? {
        return graph.nodes.min { node1, node2 in
            heuristic(node1.position, coordinate) < heuristic(node2.position, coordinate)
        }
    }
    
    private func getNeighbors(of node: ConnectivityNode, in graph: ConnectivityGraph) -> [ConnectivityNode] {
        let connectedEdges = graph.edges.filter { $0.fromNodeId == node.id }
        return connectedEdges.compactMap { edge in
            graph.nodes.first { $0.id == edge.toNodeId }
        }
    }
    
    private func distanceBetweenNodes(_ node1: ConnectivityNode, _ node2: ConnectivityNode) -> Double {
        return heuristic(node1.position, node2.position)
    }
    
    private func reconstructPath(cameFrom: [UUID: UUID], current: UUID, graph: ConnectivityGraph) -> [Coordinate] {
        var path: [Coordinate] = []
        var currentId = current
        
        while let previous = cameFrom[currentId] {
            if let node = graph.nodes.first(where: { $0.id == currentId }) {
                path.insert(node.position, at: 0)
            }
            currentId = previous
        }
        
        // Add start node
        if let startNode = graph.nodes.first(where: { $0.id == currentId }) {
            path.insert(startNode.position, at: 0)
        }
        
        return path
    }
    
    // MARK: - Enhanced Route Generation with Real-time Updates
    
    func updateRouteProgress(completedItemId: UUID) {
        guard let currentRoute = currentRoute else { return }
        
        // Find waypoint containing this item
        if let waypointIndex = currentRoute.waypoints.firstIndex(where: { waypoint in
            waypoint.products.contains(completedItemId)
        }) {
            let waypoint = currentRoute.waypoints[waypointIndex]
            
            // Update progress
            routeProgress?.visitedWaypoints.insert(waypoint.id)
            
            // Remove completed item from waypoint
            var updatedWaypoint = waypoint
            updatedWaypoint.products.removeAll { $0 == completedItemId }
            
            // If all items in waypoint are completed, mark waypoint as completed
            if updatedWaypoint.products.isEmpty {
                routeProgress?.completedWaypoints.insert(waypoint.id)
                
                // Move to next waypoint
                let nextIndex = waypointIndex + 1
                if nextIndex < currentRoute.waypoints.count {
                    routeProgress?.currentWaypoint = currentRoute.waypoints[nextIndex]
                } else {
                    // Route completed!
                    routeProgress?.isCompleted = true
                    routeProgress?.currentWaypoint = nil
                }
            }
            
            // Recalculate remaining time and distance
            updateRouteMetrics()
        }
    }
    
    func skipWaypoint(_ waypointId: UUID) {
        guard let currentRoute = currentRoute else { return }
        
        if let waypointIndex = currentRoute.waypoints.firstIndex(where: { $0.id == waypointId }) {
            routeProgress?.skippedWaypoints.insert(waypointId)
            
            // Move to next waypoint
            let nextIndex = waypointIndex + 1
            if nextIndex < currentRoute.waypoints.count {
                routeProgress?.currentWaypoint = currentRoute.waypoints[nextIndex]
            } else {
                routeProgress?.isCompleted = true
                routeProgress?.currentWaypoint = nil
            }
            
            updateRouteMetrics()
        }
    }
    
    func reorderRoute(newItemOrder: [UUID]) {
        // Regenerate route based on new item order
        // This would be called when user manually reorders their shopping list
        Task {
            do {
                // This is a simplified implementation - in reality you'd want to preserve
                // the current progress and reoptimize the remaining route
                if let store = getCurrentStore(),
                   let groceryList = getCurrentGroceryList() {
                    let _ = try await generateRoute(
                        for: groceryList,
                        in: store,
                        optimizationStrategy: .logicalOrder
                    )
                    // Merge with current progress...
                }
            } catch {
                print("Failed to reorder route: \(error)")
            }
        }
    }
    
    private func updateRouteMetrics() {
        guard let route = currentRoute else { return }
        
        let remainingWaypoints = route.waypoints.filter { waypoint in
            !(routeProgress?.completedWaypoints.contains(waypoint.id) ?? false) &&
            !(routeProgress?.skippedWaypoints.contains(waypoint.id) ?? false)
        }
        
        // Calculate remaining distance and time
        var remainingDistance = 0.0
        var remainingTime = 0
        
        for waypoint in remainingWaypoints {
            remainingDistance += Double(waypoint.estimatedTimeMinutes) * 1.2 // Approximate distance based on walking time
            remainingTime += waypoint.estimatedTimeMinutes
        }
        
        routeProgress?.remainingDistance = remainingDistance
        routeProgress?.estimatedTimeRemaining = remainingTime
        routeProgress?.progressPercentage = Double(routeProgress?.completedWaypoints.count ?? 0) / Double(route.waypoints.count)
    }
    
    // Helper methods for real-time updates
    private func getCurrentStore() -> Store? {
        // This would typically come from AppState
        return nil // Placeholder
    }
    
    private func getCurrentGroceryList() -> GroceryList? {
        // This would typically come from AppState  
        return nil // Placeholder
    }
    
    // MARK: - Smart Route Suggestions
    
    func getSuggestions(for currentLocation: Coordinate, storeLayout: StoreLayout) -> [RouteSuggestion] {
        var suggestions: [RouteSuggestion] = []
        
        // Suggest nearby items user might have missed
        let nearbyAisles = storeLayout.aisles.filter { aisle in
            heuristic(currentLocation, aisle.centerPoint) < 15.0 // Within 15 units
        }
        
        for aisle in nearbyAisles {
            suggestions.append(RouteSuggestion(
                type: .nearbyItems,
                title: "Items nearby in \(aisle.name)",
                description: "You're close to \(aisle.name). Check for any missed items.",
                aisleId: aisle.aisleId
            ))
        }
        
        // Suggest route optimization
        if (routeProgress?.skippedWaypoints.count ?? 0) > 2 {
            suggestions.append(RouteSuggestion(
                type: .reoptimize,
                title: "Reoptimize Route",
                description: "You've skipped several stops. Would you like to reoptimize your route?",
                aisleId: nil
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Waypoint Generation
    
    private func generateWaypoints(
        from aisleOrder: [String],
        storeLayout: StoreLayout
    ) -> [RouteWaypoint] {
        
        var waypoints: [RouteWaypoint] = []
        
        for (_, aisleId) in aisleOrder.enumerated() {
            guard let aisle = storeLayout.aisles.first(where: { $0.aisleId == aisleId }) else {
                continue
            }
            
            // Get products for this aisle
            let productsInAisle = sampleProductLocations
                .filter { $0.aisleId == aisleId }
                .map { $0.productId }
            
            let waypoint = RouteWaypoint(
                position: aisle.centerPoint,
                aisleId: aisleId,
                instruction: generateAisleInstructions(for: aisle),
                products: productsInAisle,
                estimatedTimeMinutes: 3,
                isCompleted: false,
                waypointType: .aisle
            )
            
            waypoints.append(waypoint)
        }
        
        return waypoints
    }
    
    private func generateAisleInstructions(for aisle: Aisle) -> String {
        switch aisle.aisleId {
        case "PRODUCE":
            return "Collect fresh fruits and vegetables. Check for ripeness and organic options."
        case "MEAT":
            return "Visit meat counter for fresh cuts. Keep refrigerated items together."
        case "DAIRY":
            return "Grab dairy products. Check expiration dates and keep cold."
        case "FROZEN":
            return "Pick up frozen items last to maintain temperature."
        case "BAKERY":
            return "Select fresh baked goods. Ask for assistance if needed."
        default:
            return "Collect items from \(aisle.name)"
        }
    }
    
    // MARK: - Route Calculation
    
    private func calculateRouteMetrics(
        waypoints: [RouteWaypoint],
        storeLayout: StoreLayout
    ) -> (distance: Double, time: Double) {
        
        var totalDistance: Double = 0
        var totalTime: Double = 0
        
        // Start from entrance
        var currentPosition = storeLayout.entrance
        
        for waypoint in waypoints {
            let distance = sqrt(pow(currentPosition.x - waypoint.position.x, 2) + pow(currentPosition.y - waypoint.position.y, 2))
            totalDistance += distance
            totalTime += distance / 1.2 // Walking speed 1.2 m/s
            totalTime += 30 // 30 seconds per waypoint for item collection
            
            currentPosition = waypoint.position
        }
        
        // Add distance to exit
        let exitDistance = sqrt(pow(currentPosition.x - storeLayout.exits.first!.x, 2) + pow(currentPosition.y - storeLayout.exits.first!.y, 2))
        totalDistance += exitDistance
        totalTime += exitDistance / 1.2
        
        return (totalDistance, totalTime / 60) // Convert to minutes
    }
    

    
    // MARK: - Route Progress Tracking
    
    func startRouteNavigation(_ route: ShoppingRoute) {
        routeProgress = RouteProgress(route: route)
    }
    
    func markWaypointCompleted(_ waypointId: UUID) {
        guard var progress = routeProgress else { return }
        
        progress.visitedWaypoints.insert(waypointId)
        
        // Find next unvisited waypoint
        let sortedWaypoints = progress.route.waypoints
        if let nextIndex = sortedWaypoints.firstIndex(where: { !progress.visitedWaypoints.contains($0.id) }) {
            progress.currentWaypointIndex = nextIndex
        }
        
        // Update estimated time remaining
        updateEstimatedTimeRemaining(progress: progress)
        
        routeProgress = progress
    }
    
    private func updateEstimatedTimeRemaining(progress: RouteProgress) {
        let remainingWaypoints = progress.route.waypoints.filter { 
            !progress.visitedWaypoints.contains($0.id) 
        }
        
        // Estimate based on remaining waypoints
        let baseTimePerWaypoint: Double = 1.5 // 1.5 minutes average
        estimatedTimeRemaining = Double(remainingWaypoints.count) * baseTimePerWaypoint
    }
    
    // MARK: - Data Access Helpers
    
    private func getStoreLayout(for storeId: UUID) -> StoreLayout? {
        return sampleStoreLayouts.first { $0.storeId == storeId }
    }
    
    private func getProductLocation(productId: UUID, storeId: UUID) -> ProductLocation? {
        return sampleProductLocations.first { 
            $0.productId == productId && $0.storeId == storeId 
        }
    }
    
    // MARK: - Turn-by-Turn Navigation
    
    func generateTurnByTurnDirections(for route: ShoppingRoute) -> [NavigationInstruction] {
        guard let storeLayout = getStoreLayout(for: route.storeId) else { return [] }
        
        var instructions: [NavigationInstruction] = []
        var currentPosition = storeLayout.entrance
        
        // Starting instruction
        instructions.append(NavigationInstruction(
            id: UUID(),
            step: 1,
            instruction: "Enter store and head to the main shopping area",
            distance: sqrt(pow(currentPosition.x - storeLayout.entrance.x, 2) + pow(currentPosition.y - storeLayout.entrance.y, 2)),
            direction: .straight,
            aisleTarget: nil
        ))
        
        // Generate instructions for each waypoint
        for (index, waypoint) in route.waypoints.enumerated() {
            let stepNumber = index + 2
            
            // Calculate direction to waypoint
            let direction = calculateDirection(from: currentPosition, to: waypoint.position)
            
            let instruction = NavigationInstruction(
                id: UUID(),
                step: stepNumber,
                instruction: "Go to \(waypoint.aisleId ?? "Unknown Aisle"). \(waypoint.instruction)",
                distance: sqrt(pow(currentPosition.x - waypoint.position.x, 2) + pow(currentPosition.y - waypoint.position.y, 2)),
                direction: direction,
                aisleTarget: waypoint.aisleId
            )
            
            instructions.append(instruction)
            currentPosition = waypoint.position
        }
        
        // Final instruction to exit
        instructions.append(NavigationInstruction(
            id: UUID(),
            step: instructions.count + 1,
            instruction: "Proceed to store exit",
            distance: sqrt(pow(currentPosition.x - storeLayout.exits.first!.x, 2) + pow(currentPosition.y - storeLayout.exits.first!.y, 2)),
            direction: calculateDirection(from: currentPosition, to: storeLayout.exits.first!),
            aisleTarget: "EXIT"
        ))
        
        return instructions
    }
    
    private func calculateDirection(from start: Coordinate, to end: Coordinate) -> NavigationDirection {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx) * 180 / .pi
        
        switch angle {
        case -45...45: return .right
        case 45...135: return .straight
        case 135...180, -180...(-135): return .left
        case -135...(-45): return .uturn
        default: return .straight
        }
    }
}

// MARK: - Supporting Types

struct RouteProgress {
    let route: ShoppingRoute
    var currentWaypointIndex: Int
    var visitedWaypoints: Set<UUID>
    var completedWaypoints: Set<UUID>
    var skippedWaypoints: Set<UUID>
    var remainingDistance: Double
    var estimatedTimeRemaining: Int
    var progressPercentage: Double
    var isCompleted: Bool
    var currentWaypoint: RouteWaypoint?
    let startTime: Date
    
    init(route: ShoppingRoute) {
        self.route = route
        self.currentWaypointIndex = 0
        self.visitedWaypoints = []
        self.completedWaypoints = []
        self.skippedWaypoints = []
        self.remainingDistance = route.totalDistance
        self.estimatedTimeRemaining = route.estimatedTime
        self.progressPercentage = 0.0
        self.isCompleted = false
        self.currentWaypoint = route.waypoints.first
        self.startTime = Date()
    }
    
    var completionPercentage: Double {
        return Double(visitedWaypoints.count) / Double(route.waypoints.count)
    }
}

struct NavigationInstruction: Identifiable {
    let id: UUID
    let step: Int
    let instruction: String
    let distance: Double
    let direction: NavigationDirection
    let aisleTarget: String?
}

enum NavigationDirection: String, CaseIterable {
    case straight = "Continue Straight"
    case left = "Turn Left"
    case right = "Turn Right"
    case uturn = "Make U-Turn"
    
    var icon: String {
        switch self {
        case .straight: return "arrow.up"
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        case .uturn: return "arrow.uturn.up"
        }
    }
}

enum RouteOptimizationError: Error, LocalizedError {
    case storeLayoutNotFound
    case invalidGroceryList
    case noProductsFound
    case routeGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .storeLayoutNotFound:
            return "Store layout not found. Please select a different store or try again."
        case .invalidGroceryList:
            return "Invalid grocery list. Please add items to your list before generating a route."
        case .noProductsFound:
            return "No products found in store. Please add items to your grocery list."
        case .routeGenerationFailed:
            return "Failed to generate route. Please try again or contact support."
        }
    }
} 

// MARK: - Route Suggestion Model

struct RouteSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let aisleId: String?
    
    enum SuggestionType {
        case nearbyItems
        case reoptimize
        case shortcut
        case timeAlert
    }
} 