//
//  StoreData.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import CoreLocation // Required for CLLocationCoordinate2D
import Foundation // For UUID
import SwiftUI // For Image

// MARK: - Store Type Enum
enum StoreType: String, CaseIterable, Codable, Hashable {
    case grocery = "Grocery"
    case pharmacy = "Pharmacy"
    case convenience = "Convenience"
    case department = "Department Store"
    case specialty = "Specialty"
    
    var icon: String {
        switch self {
        case .grocery: return "cart.fill"
        case .pharmacy: return "cross.fill"
        case .convenience: return "building.2.fill"
        case .department: return "building.fill"
        case .specialty: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .grocery: return .green
        case .pharmacy: return .blue
        case .convenience: return .orange
        case .department: return .purple
        case .specialty: return .yellow
        }
    }
}

// Define your Store struct to include location data
struct Store: Identifiable, Equatable, Codable, Hashable {
    let id: UUID // Required for Identifiable protocol
    let name: String
    let address: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let latitude: Double
    let longitude: Double
    let storeType: StoreType
    let hours: String
    let rating: Double
    let isFavorite: Bool
    
    init(id: UUID = UUID(), name: String, address: String, city: String, state: String, zip: String, phone: String, latitude: Double, longitude: Double, storeType: StoreType = .grocery, hours: String = "9AM-9PM", rating: Double = 4.5, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        self.storeType = storeType
        self.hours = hours
        self.rating = rating
        self.isFavorite = isFavorite
    }
}

// Sample store data with example LA coordinates
let sampleLAStores: [Store] = [
    Store(id: UUID(uuidString: "94D35934-26DF-4109-9634-54CA3DEAB9A0")!, name: "Lumo Downtown LA", address: "123 Main St", city: "Los Angeles", state: "CA", zip: "90012", phone: "(213) 555-1001", latitude: 34.0487, longitude: -118.2518, storeType: .grocery, hours: "7AM-10PM", rating: 4.8, isFavorite: true),
    Store(id: UUID(uuidString: "C8F17F20-9EE1-4938-9B5B-E0E8F6374299")!, name: "Lumo Santa Monica", address: "456 Ocean Ave", city: "Santa Monica", state: "CA", zip: "90401", phone: "(310) 555-2002", latitude: 34.0195, longitude: -118.4912, storeType: .grocery, hours: "8AM-9PM", rating: 4.6),
    Store(id: UUID(uuidString: "95C7EC4E-BCB6-4FDF-9791-52007BF7B4FF")!, name: "Lumo Hollywood", address: "789 Sunset Blvd", city: "Hollywood", state: "CA", zip: "90028", phone: "(323) 555-3003", latitude: 34.0901, longitude: -118.3304, storeType: .department, hours: "9AM-8PM", rating: 4.4),
    Store(id: UUID(uuidString: "A0AE1E98-77FF-45CB-BC4E-8672630B0BC8")!, name: "Lumo Pasadena", address: "101 Colorado Blvd", city: "Pasadena", state: "CA", zip: "91105", phone: "(626) 555-4004", latitude: 34.1478, longitude: -118.1445, storeType: .pharmacy, hours: "8AM-10PM", rating: 4.7),
    Store(id: UUID(uuidString: "953F30A7-532E-4D19-90FD-14046EA77AFA")!, name: "Lumo Long Beach", address: "200 Pine Ave", city: "Long Beach", state: "CA", zip: "90802", phone: "(562) 555-5005", latitude: 33.7686, longitude: -118.1956, storeType: .convenience, hours: "6AM-11PM", rating: 4.2),
    Store(id: UUID(uuidString: "DCF1E5E0-73EA-4BA4-806F-72F209D09E2E")!, name: "Lumo Beverly Hills", address: "300 Rodeo Dr", city: "Beverly Hills", state: "CA", zip: "90210", phone: "(310) 555-6006", latitude: 34.0736, longitude: -118.4004, storeType: .specialty, hours: "10AM-7PM", rating: 4.9, isFavorite: true),
    // --- Berkeley Stores ---
    Store(id: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!, name: "Berkeley Bowl", address: "2020 Oregon St", city: "Berkeley", state: "CA", zip: "94703", phone: "(510) 843-6929", latitude: 37.8590, longitude: -122.2727, storeType: .grocery, hours: "9AM-8PM", rating: 4.7),
    Store(id: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!, name: "Trader Joe's Berkeley", address: "1885 University Ave", city: "Berkeley", state: "CA", zip: "94703", phone: "(510) 204-9074", latitude: 37.8715, longitude: -122.2727, storeType: .grocery, hours: "8AM-9PM", rating: 4.6),
    Store(id: UUID(uuidString: "34BF261D-B06B-4507-A25F-D6A4D6E88734")!, name: "Safeway Berkeley", address: "1444 Shattuck Pl", city: "Berkeley", state: "CA", zip: "94709", phone: "(510) 526-3086", latitude: 37.8796, longitude: -122.2697, storeType: .grocery, hours: "6AM-12AM", rating: 4.2),
    Store(id: UUID(uuidString: "b8c9d0e1-f2b3-4567-89ab-cdef01234567")!, name: "Whole Foods Market", address: "3000 Telegraph Ave", city: "Berkeley", state: "CA", zip: "94705", phone: "(510) 649-1333", latitude: 37.8555, longitude: -122.2588, storeType: .grocery, hours: "8AM-10PM", rating: 4.5),
    Store(id: UUID(uuidString: "c9d0e1f2-b3a4-5678-9abc-def012345678")!, name: "Monterey Market", address: "1550 Hopkins St", city: "Berkeley", state: "CA", zip: "94707", phone: "(510) 526-6042", latitude: 37.8822, longitude: -122.2822, storeType: .grocery, hours: "8AM-7PM", rating: 4.8),
    Store(id: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!, name: "CVS Pharmacy Berkeley", address: "2300 Shattuck Ave", city: "Berkeley", state: "CA", zip: "94704", phone: "(510) 705-8401", latitude: 37.8688, longitude: -122.2670, storeType: .pharmacy, hours: "8AM-10PM", rating: 4.1)
]

// Extension to make it easier to get CLLocationCoordinate2D from Store
extension Store {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Product Models

struct Product: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let brand: String?
    let description: String?
    let imageURL: String?
    let basePrice: Double
    let unit: String // e.g., "each", "lb", "oz"
    let nutritionInfo: NutritionInfo?
    let tags: [String] // e.g., "organic", "gluten-free"
    
    init(id: UUID = UUID(), name: String, category: String, brand: String? = nil, description: String? = nil, imageURL: String? = nil, basePrice: Double, unit: String = "each", nutritionInfo: NutritionInfo? = nil, tags: [String] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.description = description
        self.imageURL = imageURL
        self.basePrice = basePrice
        self.unit = unit
        self.nutritionInfo = nutritionInfo
        self.tags = tags
    }
}

struct NutritionInfo: Codable, Hashable {
    let calories: Int?
    let protein: Double? // grams
    let carbs: Double? // grams
    let fat: Double? // grams
    let fiber: Double? // grams
    let sugar: Double? // grams
    let sodium: Double? // mg
}

struct StoreProduct: Identifiable, Codable, Hashable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let price: Double
    let stockQuantity: Int
    let isAvailable: Bool
    let lastUpdated: Date
    let dealType: DealType?
    let dealDescription: String?
    
    enum DealType: String, Codable, CaseIterable {
        case bogo = "BOGO"
        case percentageOff = "Percentage Off"
        case dollarOff = "Dollar Off"
        case clearance = "Clearance"
        case none = "None"
    }
    
    init(id: UUID = UUID(), storeId: UUID, productId: UUID, price: Double, stockQuantity: Int, isAvailable: Bool = true, lastUpdated: Date = Date(), dealType: DealType? = nil, dealDescription: String? = nil) {
        self.id = id
        self.storeId = storeId
        self.productId = productId
        self.price = price
        self.stockQuantity = stockQuantity
        self.isAvailable = isAvailable
        self.lastUpdated = lastUpdated
        self.dealType = dealType
        self.dealDescription = dealDescription
    }
}

// MARK: - Store Product Service

class StoreProductService: ObservableObject {
    static let shared = StoreProductService()
    
    @Published var products: [Product] = []
    @Published var storeProducts: [StoreProduct] = []
    
    private init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Sample products for your stores
        products = [
            Product(id: UUID(), name: "Organic Bananas", category: "Produce", brand: "Local Farm", basePrice: 2.99, unit: "lb", tags: ["organic"]),
            Product(id: UUID(), name: "Whole Milk", category: "Dairy", brand: "Berkeley Farms", basePrice: 4.49, unit: "gallon"),
            Product(id: UUID(), name: "Trader Joe's Everything Bagel", category: "Bakery", brand: "Trader Joe's", basePrice: 3.99, unit: "pack"),
            Product(id: UUID(), name: "Two Buck Chuck Chardonnay", category: "Wine", brand: "Charles Shaw", basePrice: 2.99, unit: "bottle"),
            Product(id: UUID(), name: "Advil", category: "Health", brand: "Pfizer", basePrice: 8.99, unit: "bottle"),
            Product(id: UUID(), name: "Shampoo", category: "Beauty", brand: "CVS", basePrice: 5.99, unit: "bottle")
        ]
        
        // Generate store-specific pricing for your stores
        generateStoreProducts()
    }
    
    private func generateStoreProducts() {
        let stores = sampleLAStores
        storeProducts = []
        
        for store in stores {
            for product in products {
                let priceMultiplier = getPriceMultiplier(for: store)
                let adjustedPrice = product.basePrice * priceMultiplier
                let stockLevel = Int.random(in: 0...50)
                
                let storeProduct = StoreProduct(
                    storeId: store.id,
                    productId: product.id,
                    price: adjustedPrice,
                    stockQuantity: stockLevel,
                    isAvailable: stockLevel > 0
                )
                storeProducts.append(storeProduct)
            }
        }
    }
    
    private func getPriceMultiplier(for store: Store) -> Double {
        switch store.name {
        case "Berkeley Bowl":
            return 1.05 // Slightly higher for organic quality
        case "Trader Joe's Berkeley":
            return 0.95 // TJ's value pricing
        case "Whole Foods Market":
            return 1.15 // Premium pricing
        case "CVS Pharmacy Berkeley":
            return 1.10 // Convenience markup
        default:
            return 1.0
        }
    }
    
    func getProducts(for storeId: UUID) -> [StoreProduct] {
        return storeProducts.filter { $0.storeId == storeId }
    }
    
    func getProduct(by id: UUID) -> Product? {
        return products.first { $0.id == id }
    }
    
    func getStoreProducts(for storeId: UUID) async throws -> [StoreProduct] {
        return storeProducts.filter { $0.storeId == storeId }
    }
    
    func searchProducts(_ query: String, storeId: UUID) async throws -> [StoreProduct] {
        let filteredProducts = storeProducts.filter { storeProduct in
            storeProduct.storeId == storeId &&
            (getProduct(by: storeProduct.productId)?.name.localizedCaseInsensitiveContains(query) ?? false)
        }
        return filteredProducts
    }
    
    func getLowStockProducts() async throws -> [StoreProduct] {
        return storeProducts.filter { $0.stockQuantity < 5 && $0.isAvailable }
    }
}

// MARK: - Shopping Insights

struct ShoppingInsights: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let value: String
    let type: InsightType
    let category: String?
    
    enum InsightType: String, Codable, CaseIterable {
        case savings = "Savings"
        case frequency = "Frequency"
        case preference = "Preference"
        case trend = "Trend"
        case recommendation = "Recommendation"
    }
    
    static func generateInsights(from history: [ShoppingHistory]) -> [ShoppingInsights] {
        var insights: [ShoppingInsights] = []
        
        // Sample insights based on shopping history
        if !history.isEmpty {
            let totalSpent = history.reduce(into: 0.0) { $0 += $1.totalSpent }
            let avgOrder = totalSpent / Double(history.count)
            
            insights.append(
                ShoppingInsights(
                    title: "Average Order Value",
                    description: "Your typical grocery spending per trip",
                    value: String(format: "$%.2f", avgOrder),
                    type: .trend,
                    category: "Spending"
                )
            )
            
            insights.append(
                ShoppingInsights(
                    title: "Total Savings",
                    description: "Amount saved through deals and discounts",
                    value: String(format: "$%.2f", totalSpent * 0.15), // Assume 15% savings
                    type: .savings,
                    category: "Deals"
                )
            )
            
            insights.append(
                ShoppingInsights(
                    title: "Shopping Frequency",
                    description: "Average trips per month",
                    value: "\(history.count) trips",
                    type: .frequency,
                    category: "Habits"
                )
            )
        }
        
        return insights
    }
}

// MARK: - Store Layout & Routing Models

struct Coordinate: Codable, Hashable {
    let x: Double
    let y: Double
}

struct MapDimensions: Codable, Hashable {
    let width: Double
    let height: Double
}

struct CheckoutLocation: Identifiable, Codable, Hashable {
    let id = UUID()
    let position: Coordinate
    let type: CheckoutType
    let maxItems: Int?
    
    enum CheckoutType: String, Codable, CaseIterable {
        case regular = "Regular"
        case express = "Express"
        case selfService = "Self-Service"
    }
}

struct AisleSubSection: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let position: Coordinate
    let side: AisleSide
    
    enum AisleSide: String, Codable, CaseIterable {
        case left = "Left"
        case right = "Right"
        case center = "Center"
    }
}

struct Aisle: Identifiable, Codable, Hashable {
    let id = UUID()
    let aisleId: String
    let name: String
    let bounds: [Coordinate] // Polygon defining aisle boundaries
    let centerPoint: Coordinate
    let category: AisleCategory
    let subSections: [AisleSubSection]
    
    enum AisleCategory: String, Codable, CaseIterable {
        case produce = "Produce"
        case meat = "Meat & Seafood"
        case dairy = "Dairy"
        case frozen = "Frozen"
        case bakery = "Bakery"
        case pantry = "Pantry"
        case snacks = "Snacks"
        case beverages = "Beverages"
        case health = "Health & Beauty"
        case household = "Household"
        case pharmacy = "Pharmacy"
    }
}

struct ConnectivityNode: Identifiable, Codable, Hashable {
    let id = UUID()
    let position: Coordinate
    let nodeType: NodeType
    let connectedAisles: [String] // Aisle IDs
    
    enum NodeType: String, Codable, CaseIterable {
        case entrance = "Entrance"
        case exit = "Exit"
        case intersection = "Intersection"
        case aisleEntry = "Aisle Entry"
        case checkout = "Checkout"
    }
}

struct ConnectivityEdge: Identifiable, Codable, Hashable {
    let id = UUID()
    let fromNodeId: UUID
    let toNodeId: UUID
    let distance: Double
    let walkingTime: Double // In seconds
}

struct ConnectivityGraph: Codable, Hashable {
    let nodes: [ConnectivityNode]
    let edges: [ConnectivityEdge]
}

struct ProductLocation: Identifiable, Codable, Hashable {
    let id = UUID()
    let productId: UUID
    let aisleId: String
    let subSectionName: String?
    let position: Coordinate?
    let storeId: UUID
}

struct StoreLayout: Identifiable, Codable, Hashable {
    let id: UUID
    let storeId: UUID
    let entrance: Coordinate
    let exits: [Coordinate]
    let checkouts: [CheckoutLocation]
    let aisles: [Aisle]
    let connectivityGraph: ConnectivityGraph
    let mapDimensions: MapDimensions
    let lastUpdated: Date
    
    init(id: UUID = UUID(), storeId: UUID, entrance: Coordinate, exits: [Coordinate], checkouts: [CheckoutLocation], aisles: [Aisle], connectivityGraph: ConnectivityGraph, mapDimensions: MapDimensions, lastUpdated: Date = Date()) {
        self.id = id
        self.storeId = storeId
        self.entrance = entrance
        self.exits = exits
        self.checkouts = checkouts
        self.aisles = aisles
        self.connectivityGraph = connectivityGraph
        self.mapDimensions = mapDimensions
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Shopping Route Models

struct ShoppingRoute: Identifiable, Codable, Hashable {
    let id = UUID()
    let storeId: UUID
    let waypoints: [RouteWaypoint]
    let totalDistance: Double
    let estimatedTime: Int // In minutes
    let optimizationStrategy: OptimizationStrategy
    let createdAt: Date
    
    enum OptimizationStrategy: String, Codable, CaseIterable {
        case shortestDistance = "Shortest Distance"
        case fastestTime = "Fastest Time"
        case logicalOrder = "Logical Shopping Order"
    }
}

struct RouteWaypoint: Identifiable, Codable, Hashable {
    let id = UUID()
    let position: Coordinate
    let aisleId: String?
    let instruction: String
    var products: [UUID] // Product IDs to collect at this waypoint
    let estimatedTimeMinutes: Int
    let isCompleted: Bool
    let waypointType: WaypointType
    
    enum WaypointType: String, Codable, CaseIterable {
        case entrance = "Entrance"
        case aisle = "Aisle"
        case checkout = "Checkout"
        case exit = "Exit"
    }
}

// MARK: - Navigation Instructions
// Note: NavigationInstruction is defined in RouteOptimizationManager.swift

// MARK: - Sample Store Layouts for YOUR Existing Stores

let sampleStoreLayouts: [StoreLayout] = [
    // Lumo Downtown LA - Main Store
    StoreLayout(
        storeId: UUID(uuidString: "94D35934-26DF-4109-9634-54CA3DEAB9A0")!, // Lumo Downtown LA
        entrance: Coordinate(x: 2.0, y: 0.0),
        exits: [
            Coordinate(x: 2.0, y: 0.0),   // Main entrance/exit
            Coordinate(x: 48.0, y: 0.0)   // Secondary exit
        ],
        checkouts: [
            CheckoutLocation(position: Coordinate(x: 40.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 42.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 44.0, y: 4.0), type: .express, maxItems: 15),
            CheckoutLocation(position: Coordinate(x: 46.0, y: 4.0), type: .selfService, maxItems: nil)
        ],
        aisles: [
            // Produce Section
            Aisle(aisleId: "PRODUCE", name: "Fresh Produce", 
                  bounds: [Coordinate(x: 4, y: 6), Coordinate(x: 18, y: 6), Coordinate(x: 18, y: 12), Coordinate(x: 4, y: 12)],
                  centerPoint: Coordinate(x: 11, y: 9), category: .produce,
                  subSections: [
                      AisleSubSection(name: "Fruits", position: Coordinate(x: 7, y: 8), side: .left),
                      AisleSubSection(name: "Vegetables", position: Coordinate(x: 11, y: 8), side: .center),
                      AisleSubSection(name: "Organic", position: Coordinate(x: 15, y: 8), side: .right)
                  ]),
            
            // Dairy Section
            Aisle(aisleId: "DAIRY", name: "Dairy & Eggs",
                  bounds: [Coordinate(x: 20, y: 6), Coordinate(x: 34, y: 6), Coordinate(x: 34, y: 12), Coordinate(x: 20, y: 12)],
                  centerPoint: Coordinate(x: 27, y: 9), category: .dairy,
                  subSections: [
                      AisleSubSection(name: "Milk & Yogurt", position: Coordinate(x: 24, y: 9), side: .center),
                      AisleSubSection(name: "Cheese", position: Coordinate(x: 30, y: 9), side: .center)
                  ]),
            
            // Meat & Seafood
            Aisle(aisleId: "MEAT", name: "Meat & Seafood",
                  bounds: [Coordinate(x: 36, y: 6), Coordinate(x: 50, y: 6), Coordinate(x: 50, y: 12), Coordinate(x: 36, y: 12)],
                  centerPoint: Coordinate(x: 43, y: 9), category: .meat,
                  subSections: [
                      AisleSubSection(name: "Fresh Meat", position: Coordinate(x: 40, y: 9), side: .center),
                      AisleSubSection(name: "Seafood", position: Coordinate(x: 46, y: 9), side: .center)
                  ]),
            
            // Pantry Aisles
            Aisle(aisleId: "A1", name: "Aisle 1 - Pantry Staples",
                  bounds: [Coordinate(x: 4, y: 14), Coordinate(x: 18, y: 14), Coordinate(x: 18, y: 20), Coordinate(x: 4, y: 20)],
                  centerPoint: Coordinate(x: 11, y: 17), category: .pantry,
                  subSections: [
                      AisleSubSection(name: "Canned Goods", position: Coordinate(x: 7, y: 17), side: .left),
                      AisleSubSection(name: "Pasta & Rice", position: Coordinate(x: 11, y: 17), side: .center),
                      AisleSubSection(name: "Sauces", position: Coordinate(x: 15, y: 17), side: .right)
                  ]),
            
            Aisle(aisleId: "A2", name: "Aisle 2 - Snacks & Beverages",
                  bounds: [Coordinate(x: 20, y: 14), Coordinate(x: 34, y: 14), Coordinate(x: 34, y: 20), Coordinate(x: 20, y: 20)],
                  centerPoint: Coordinate(x: 27, y: 17), category: .snacks,
                  subSections: [
                      AisleSubSection(name: "Snacks", position: Coordinate(x: 24, y: 17), side: .center),
                      AisleSubSection(name: "Beverages", position: Coordinate(x: 30, y: 17), side: .center)
                  ]),
            
            Aisle(aisleId: "A3", name: "Aisle 3 - Household & Personal Care",
                  bounds: [Coordinate(x: 36, y: 14), Coordinate(x: 50, y: 14), Coordinate(x: 50, y: 20), Coordinate(x: 36, y: 20)],
                  centerPoint: Coordinate(x: 43, y: 17), category: .household,
                  subSections: [
                      AisleSubSection(name: "Cleaning", position: Coordinate(x: 40, y: 17), side: .center),
                      AisleSubSection(name: "Personal Care", position: Coordinate(x: 46, y: 17), side: .center)
                  ]),
            
            // Frozen Section
            Aisle(aisleId: "FROZEN", name: "Frozen Foods",
                  bounds: [Coordinate(x: 4, y: 22), Coordinate(x: 25, y: 22), Coordinate(x: 25, y: 28), Coordinate(x: 4, y: 28)],
                  centerPoint: Coordinate(x: 14, y: 25), category: .frozen,
                  subSections: [
                      AisleSubSection(name: "Frozen Meals", position: Coordinate(x: 10, y: 25), side: .center),
                      AisleSubSection(name: "Ice Cream", position: Coordinate(x: 20, y: 25), side: .center)
                  ]),
            
            // Bakery
            Aisle(aisleId: "BAKERY", name: "Fresh Bakery",
                  bounds: [Coordinate(x: 27, y: 22), Coordinate(x: 50, y: 22), Coordinate(x: 50, y: 28), Coordinate(x: 27, y: 28)],
                  centerPoint: Coordinate(x: 38, y: 25), category: .bakery,
                  subSections: [
                      AisleSubSection(name: "Fresh Bread", position: Coordinate(x: 32, y: 25), side: .center),
                      AisleSubSection(name: "Pastries", position: Coordinate(x: 44, y: 25), side: .center)
                  ])
        ],
        connectivityGraph: ConnectivityGraph(
            nodes: [
                ConnectivityNode(position: Coordinate(x: 2.0, y: 0.0), nodeType: .entrance, connectedAisles: ["PRODUCE"]),
                ConnectivityNode(position: Coordinate(x: 11, y: 9), nodeType: .aisleEntry, connectedAisles: ["PRODUCE"]),
                ConnectivityNode(position: Coordinate(x: 27, y: 9), nodeType: .aisleEntry, connectedAisles: ["DAIRY"]),
                ConnectivityNode(position: Coordinate(x: 43, y: 9), nodeType: .aisleEntry, connectedAisles: ["MEAT"]),
                ConnectivityNode(position: Coordinate(x: 42, y: 4), nodeType: .checkout, connectedAisles: [])
            ],
            edges: []
        ),
        mapDimensions: MapDimensions(width: 60.0, height: 35.0)
    ),
    
    // Berkeley Bowl - Large Organic Grocery Store
    StoreLayout(
        storeId: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!, // Berkeley Bowl
        entrance: Coordinate(x: 2.0, y: 0.0),
        exits: [
            Coordinate(x: 2.0, y: 0.0),   // Main entrance/exit
            Coordinate(x: 58.0, y: 0.0)   // Secondary exit
        ],
        checkouts: [
            CheckoutLocation(position: Coordinate(x: 50.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 52.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 54.0, y: 4.0), type: .express, maxItems: 15),
            CheckoutLocation(position: Coordinate(x: 56.0, y: 4.0), type: .selfService, maxItems: nil)
        ],
        aisles: [
            // Organic Produce Section (Berkeley Bowl's specialty)
            Aisle(aisleId: "PRODUCE", name: "Organic Produce", 
                  bounds: [Coordinate(x: 4, y: 6), Coordinate(x: 22, y: 6), Coordinate(x: 22, y: 12), Coordinate(x: 4, y: 12)],
                  centerPoint: Coordinate(x: 13, y: 9), category: .produce,
                  subSections: [
                      AisleSubSection(name: "Organic Fruits", position: Coordinate(x: 8, y: 8), side: .left),
                      AisleSubSection(name: "Local Vegetables", position: Coordinate(x: 13, y: 8), side: .center),
                      AisleSubSection(name: "Herbs & Specialty", position: Coordinate(x: 18, y: 8), side: .right)
                  ]),
            
            // Bulk Foods Section
            Aisle(aisleId: "BULK", name: "Bulk Foods",
                  bounds: [Coordinate(x: 24, y: 6), Coordinate(x: 40, y: 6), Coordinate(x: 40, y: 12), Coordinate(x: 24, y: 12)],
                  centerPoint: Coordinate(x: 32, y: 9), category: .pantry,
                  subSections: [
                      AisleSubSection(name: "Grains & Nuts", position: Coordinate(x: 28, y: 9), side: .center),
                      AisleSubSection(name: "Spices & Herbs", position: Coordinate(x: 36, y: 9), side: .center)
                  ]),
            
            // Dairy & Cheese Section
            Aisle(aisleId: "DAIRY", name: "Dairy & Artisan Cheese",
                  bounds: [Coordinate(x: 42, y: 6), Coordinate(x: 60, y: 6), Coordinate(x: 60, y: 12), Coordinate(x: 42, y: 12)],
                  centerPoint: Coordinate(x: 51, y: 9), category: .dairy,
                  subSections: [
                      AisleSubSection(name: "Organic Dairy", position: Coordinate(x: 46, y: 9), side: .left),
                      AisleSubSection(name: "Artisan Cheese", position: Coordinate(x: 56, y: 9), side: .right)
                  ]),
            
            // Center Aisles
            Aisle(aisleId: "A1", name: "Aisle 1 - Natural Foods",
                  bounds: [Coordinate(x: 6, y: 14), Coordinate(x: 58, y: 14), Coordinate(x: 58, y: 18), Coordinate(x: 6, y: 18)],
                  centerPoint: Coordinate(x: 32, y: 16), category: .pantry,
                  subSections: [
                      AisleSubSection(name: "Organic Pantry", position: Coordinate(x: 20, y: 16), side: .left),
                      AisleSubSection(name: "Healthy Snacks", position: Coordinate(x: 44, y: 16), side: .right)
                  ]),
                  
            Aisle(aisleId: "A2", name: "Aisle 2 - International Foods",
                  bounds: [Coordinate(x: 6, y: 20), Coordinate(x: 58, y: 20), Coordinate(x: 58, y: 24), Coordinate(x: 6, y: 24)],
                  centerPoint: Coordinate(x: 32, y: 22), category: .pantry,
                  subSections: [
                      AisleSubSection(name: "Asian Foods", position: Coordinate(x: 20, y: 22), side: .left),
                      AisleSubSection(name: "European Foods", position: Coordinate(x: 44, y: 22), side: .right)
                  ])
        ],
        connectivityGraph: ConnectivityGraph(
            nodes: [
                ConnectivityNode(position: Coordinate(x: 2, y: 0), nodeType: .entrance, connectedAisles: []),
                ConnectivityNode(position: Coordinate(x: 13, y: 6), nodeType: .aisleEntry, connectedAisles: ["PRODUCE"]),
                ConnectivityNode(position: Coordinate(x: 32, y: 6), nodeType: .aisleEntry, connectedAisles: ["BULK"]),
                ConnectivityNode(position: Coordinate(x: 51, y: 6), nodeType: .aisleEntry, connectedAisles: ["DAIRY"]),
                ConnectivityNode(position: Coordinate(x: 32, y: 14), nodeType: .aisleEntry, connectedAisles: ["A1"]),
                ConnectivityNode(position: Coordinate(x: 32, y: 20), nodeType: .aisleEntry, connectedAisles: ["A2"]),
                ConnectivityNode(position: Coordinate(x: 52, y: 4), nodeType: .checkout, connectedAisles: []),
                ConnectivityNode(position: Coordinate(x: 58, y: 0), nodeType: .exit, connectedAisles: [])
            ],
            edges: [
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 15.0, walkingTime: 30),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 20.0, walkingTime: 40),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 18.0, walkingTime: 36)
            ]
        ),
        mapDimensions: MapDimensions(width: 64.0, height: 28.0)
    ),
    
    // Trader Joe's Berkeley - Compact Specialty Grocery
    StoreLayout(
        storeId: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!, // Trader Joe's Berkeley
        entrance: Coordinate(x: 2.0, y: 0.0),
        exits: [
            Coordinate(x: 2.0, y: 0.0)   // Single entrance/exit
        ],
        checkouts: [
            CheckoutLocation(position: Coordinate(x: 28.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 30.0, y: 4.0), type: .regular, maxItems: nil)
        ],
        aisles: [
            // Produce Section
            Aisle(aisleId: "PRODUCE", name: "Fresh Produce", 
                  bounds: [Coordinate(x: 4, y: 6), Coordinate(x: 16, y: 6), Coordinate(x: 16, y: 10), Coordinate(x: 4, y: 10)],
                  centerPoint: Coordinate(x: 10, y: 8), category: .produce,
                  subSections: [
                      AisleSubSection(name: "Organic Produce", position: Coordinate(x: 10, y: 8), side: .center)
                  ]),
            
            // Frozen Section
            Aisle(aisleId: "FROZEN", name: "Frozen Foods",
                  bounds: [Coordinate(x: 18, y: 6), Coordinate(x: 32, y: 6), Coordinate(x: 32, y: 10), Coordinate(x: 18, y: 10)],
                  centerPoint: Coordinate(x: 25, y: 8), category: .frozen,
                  subSections: [
                      AisleSubSection(name: "TJ's Frozen Meals", position: Coordinate(x: 25, y: 8), side: .center)
                  ]),
            
            // Center Aisles (Trader Joe's Specialties)
            Aisle(aisleId: "A1", name: "Aisle 1 - TJ's Favorites",
                  bounds: [Coordinate(x: 6, y: 12), Coordinate(x: 30, y: 12), Coordinate(x: 30, y: 16), Coordinate(x: 6, y: 16)],
                  centerPoint: Coordinate(x: 18, y: 14), category: .pantry,
                  subSections: [
                      AisleSubSection(name: "Snacks & Nuts", position: Coordinate(x: 12, y: 14), side: .left),
                      AisleSubSection(name: "Condiments & Sauces", position: Coordinate(x: 24, y: 14), side: .right)
                  ]),
                  
            Aisle(aisleId: "A2", name: "Aisle 2 - Wine & Beverages",
                  bounds: [Coordinate(x: 6, y: 18), Coordinate(x: 30, y: 18), Coordinate(x: 30, y: 22), Coordinate(x: 6, y: 22)],
                  centerPoint: Coordinate(x: 18, y: 20), category: .beverages,
                  subSections: [
                      AisleSubSection(name: "Two Buck Chuck", position: Coordinate(x: 12, y: 20), side: .left),
                      AisleSubSection(name: "Beverages", position: Coordinate(x: 24, y: 20), side: .right)
                  ])
        ],
        connectivityGraph: ConnectivityGraph(
            nodes: [
                ConnectivityNode(position: Coordinate(x: 2, y: 0), nodeType: .entrance, connectedAisles: []),
                ConnectivityNode(position: Coordinate(x: 10, y: 6), nodeType: .aisleEntry, connectedAisles: ["PRODUCE"]),
                ConnectivityNode(position: Coordinate(x: 25, y: 6), nodeType: .aisleEntry, connectedAisles: ["FROZEN"]),
                ConnectivityNode(position: Coordinate(x: 18, y: 12), nodeType: .aisleEntry, connectedAisles: ["A1"]),
                ConnectivityNode(position: Coordinate(x: 18, y: 18), nodeType: .aisleEntry, connectedAisles: ["A2"]),
                ConnectivityNode(position: Coordinate(x: 29, y: 4), nodeType: .checkout, connectedAisles: [])
            ],
            edges: [
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 12.0, walkingTime: 24),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 15.0, walkingTime: 30),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 10.0, walkingTime: 20)
            ]
        ),
        mapDimensions: MapDimensions(width: 34.0, height: 24.0)
    ),
    
    // CVS Pharmacy Berkeley - Pharmacy Layout
    StoreLayout(
        storeId: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!, // CVS Pharmacy Berkeley
        entrance: Coordinate(x: 2.0, y: 0.0),
        exits: [
            Coordinate(x: 2.0, y: 0.0)   // Single entrance/exit
        ],
        checkouts: [
            CheckoutLocation(position: Coordinate(x: 20.0, y: 4.0), type: .regular, maxItems: nil),
            CheckoutLocation(position: Coordinate(x: 22.0, y: 4.0), type: .selfService, maxItems: nil)
        ],
        aisles: [
            // Pharmacy Section
            Aisle(aisleId: "PHARMACY", name: "Pharmacy", 
                  bounds: [Coordinate(x: 4, y: 6), Coordinate(x: 14, y: 6), Coordinate(x: 14, y: 10), Coordinate(x: 4, y: 10)],
                  centerPoint: Coordinate(x: 9, y: 8), category: .pharmacy,
                  subSections: [
                      AisleSubSection(name: "Prescription Pickup", position: Coordinate(x: 9, y: 8), side: .center)
                  ]),
            
            // Health & Beauty
            Aisle(aisleId: "HBA", name: "Health & Beauty",
                  bounds: [Coordinate(x: 16, y: 6), Coordinate(x: 26, y: 6), Coordinate(x: 26, y: 10), Coordinate(x: 16, y: 10)],
                  centerPoint: Coordinate(x: 21, y: 8), category: .health,
                  subSections: [
                      AisleSubSection(name: "Cosmetics", position: Coordinate(x: 19, y: 8), side: .left),
                      AisleSubSection(name: "Vitamins", position: Coordinate(x: 23, y: 8), side: .right)
                  ]),
            
            // Snacks & Beverages
            Aisle(aisleId: "A1", name: "Aisle 1 - Snacks & Drinks",
                  bounds: [Coordinate(x: 6, y: 12), Coordinate(x: 24, y: 12), Coordinate(x: 24, y: 16), Coordinate(x: 6, y: 16)],
                  centerPoint: Coordinate(x: 15, y: 14), category: .snacks,
                  subSections: [
                      AisleSubSection(name: "Snacks", position: Coordinate(x: 12, y: 14), side: .left),
                      AisleSubSection(name: "Beverages", position: Coordinate(x: 18, y: 14), side: .right)
                  ])
        ],
        connectivityGraph: ConnectivityGraph(
            nodes: [
                ConnectivityNode(position: Coordinate(x: 2, y: 0), nodeType: .entrance, connectedAisles: []),
                ConnectivityNode(position: Coordinate(x: 9, y: 6), nodeType: .aisleEntry, connectedAisles: ["PHARMACY"]),
                ConnectivityNode(position: Coordinate(x: 21, y: 6), nodeType: .aisleEntry, connectedAisles: ["HBA"]),
                ConnectivityNode(position: Coordinate(x: 15, y: 12), nodeType: .aisleEntry, connectedAisles: ["A1"]),
                ConnectivityNode(position: Coordinate(x: 21, y: 4), nodeType: .checkout, connectedAisles: [])
            ],
            edges: [
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 8.0, walkingTime: 16),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 12.0, walkingTime: 24),
                ConnectivityEdge(fromNodeId: UUID(), toNodeId: UUID(), distance: 10.0, walkingTime: 20)
            ]
        ),
        mapDimensions: MapDimensions(width: 28.0, height: 18.0)
    )
]

// MARK: - Product Location Mappings for YOUR Stores

let sampleProductLocations: [ProductLocation] = [
    // Berkeley Bowl Product Locations
    ProductLocation(productId: UUID(), aisleId: "PRODUCE", subSectionName: "Organic Fruits", position: nil, storeId: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!),
    ProductLocation(productId: UUID(), aisleId: "PRODUCE", subSectionName: "Local Vegetables", position: nil, storeId: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!),
    ProductLocation(productId: UUID(), aisleId: "BULK", subSectionName: "Grains & Nuts", position: nil, storeId: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!),
    ProductLocation(productId: UUID(), aisleId: "DAIRY", subSectionName: "Organic Dairy", position: nil, storeId: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!),
    
    // Trader Joe's Berkeley Product Locations  
    ProductLocation(productId: UUID(), aisleId: "PRODUCE", subSectionName: "Organic Produce", position: nil, storeId: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!),
    ProductLocation(productId: UUID(), aisleId: "FROZEN", subSectionName: "TJ's Frozen Meals", position: nil, storeId: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!),
    ProductLocation(productId: UUID(), aisleId: "A1", subSectionName: "Snacks & Nuts", position: nil, storeId: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!),
    ProductLocation(productId: UUID(), aisleId: "A2", subSectionName: "Two Buck Chuck", position: nil, storeId: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!),
    
    // CVS Pharmacy Berkeley Product Locations
    ProductLocation(productId: UUID(), aisleId: "PHARMACY", subSectionName: "Prescription Pickup", position: nil, storeId: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!),
    ProductLocation(productId: UUID(), aisleId: "HBA", subSectionName: "Cosmetics", position: nil, storeId: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!),
    ProductLocation(productId: UUID(), aisleId: "HBA", subSectionName: "Vitamins", position: nil, storeId: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!),
    ProductLocation(productId: UUID(), aisleId: "A1", subSectionName: "Snacks", position: nil, storeId: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!)
]

// MARK: - Convenience Functions

extension StoreLayout {
    func getAisle(by aisleId: String) -> Aisle? {
        return aisles.first { $0.aisleId == aisleId }
    }
    
    func getProductLocation(for productId: UUID) -> ProductLocation? {
        return sampleProductLocations.first { $0.productId == productId && $0.storeId == self.storeId }
    }
}
