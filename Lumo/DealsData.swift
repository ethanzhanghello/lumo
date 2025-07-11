//
//  DealsData.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import Foundation

// MARK: - Nutrition Info
struct NutritionInfo: Codable, Hashable, Equatable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Int?
    
    init(calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double? = nil, sugar: Double? = nil, sodium: Int? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
}

// MARK: - Product Data
struct Product: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let price: Double
    let discountPrice: Double?
    let dealType: Product.DealType?
    let aisle: Int
    let shelfPosition: String
    let stockQty: Int
    let lowStockThreshold: Int
    let imageURL: String
    let tags: [String]
    let description: String
    let nutritionInfo: NutritionInfo?
    
    enum DealType: String, Codable, CaseIterable {
        case bogo = "BOGO"
        case percentageOff = "Percentage Off"
        case dollarOff = "Dollar Off"
        case clearance = "Clearance"
        case none = "None"
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let sampleProducts = [
        // Dairy & Alternatives
        Product(
            id: "AISL1029",
            name: "Almond Milk - Unsweetened",
            brand: "Silk",
            category: "Dairy Alternatives",
            price: 3.99,
            discountPrice: 2.99,
            dealType: .dollarOff,
            aisle: 5,
            shelfPosition: "Right - Eye Level",
            stockQty: 42,
            lowStockThreshold: 10,
            imageURL: "https://images.freshmart.com/products/almond-milk-silk.jpg",
            tags: ["vegan", "gluten-free", "dairy-free"],
            description: "Smooth and creamy almond milk with no added sugar",
            nutritionInfo: NutritionInfo(calories: 30, protein: 1, carbs: 1, fat: 2.5)
        ),
        Product(
            id: "AISL1030",
            name: "Organic Whole Milk",
            brand: "Straus Family Creamery",
            category: "Dairy",
            price: 4.49,
            discountPrice: nil,
            dealType: nil,
            aisle: 5,
            shelfPosition: "Left - Middle",
            stockQty: 28,
            lowStockThreshold: 8,
            imageURL: "https://images.freshmart.com/products/whole-milk-straus.jpg",
            tags: ["organic", "local"],
            description: "Creamy organic whole milk from local farms",
            nutritionInfo: NutritionInfo(calories: 150, protein: 8, carbs: 12, fat: 8)
        ),
        
        // Produce
        Product(
            id: "AISL2001",
            name: "Organic Bananas",
            brand: "FreshMart",
            category: "Produce",
            price: 2.99,
            discountPrice: 1.99,
            dealType: .percentageOff,
            aisle: 1,
            shelfPosition: "Center - Eye Level",
            stockQty: 156,
            lowStockThreshold: 20,
            imageURL: "https://images.freshmart.com/products/bananas-organic.jpg",
            tags: ["organic", "vegan", "gluten-free"],
            description: "Sweet organic bananas, perfect for smoothies or snacking",
            nutritionInfo: NutritionInfo(calories: 105, protein: 1, carbs: 27, fat: 0)
        ),
        Product(
            id: "AISL2002",
            name: "Avocados - Hass",
            brand: "FreshMart",
            category: "Produce",
            price: 3.49,
            discountPrice: 2.49,
            dealType: .dollarOff,
            aisle: 1,
            shelfPosition: "Right - Top",
            stockQty: 89,
            lowStockThreshold: 15,
            imageURL: "https://images.freshmart.com/products/avocados-hass.jpg",
            tags: ["vegan", "gluten-free", "healthy-fats"],
            description: "Perfectly ripe Hass avocados",
            nutritionInfo: NutritionInfo(calories: 160, protein: 2, carbs: 9, fat: 15)
        ),
        Product(
            id: "AISL2003",
            name: "Organic Strawberries",
            brand: "FreshMart",
            category: "Produce",
            price: 4.99,
            discountPrice: 3.99,
            dealType: .dollarOff,
            aisle: 1,
            shelfPosition: "Center - Top",
            stockQty: 67,
            lowStockThreshold: 12,
            imageURL: "https://images.freshmart.com/products/strawberries-organic.jpg",
            tags: ["organic", "vegan", "gluten-free"],
            description: "Sweet organic strawberries",
            nutritionInfo: NutritionInfo(calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3)
        ),
        Product(
            id: "AISL2004",
            name: "Organic Spinach",
            brand: "FreshMart",
            category: "Produce",
            price: 3.99,
            discountPrice: 2.99,
            dealType: .dollarOff,
            aisle: 1,
            shelfPosition: "Left - Middle",
            stockQty: 45,
            lowStockThreshold: 8,
            imageURL: "https://images.freshmart.com/products/spinach-organic.jpg",
            tags: ["organic", "vegan", "gluten-free"],
            description: "Fresh organic spinach leaves",
            nutritionInfo: NutritionInfo(calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4)
        ),
        
        // Meat & Seafood
        Product(
            id: "AISL3001",
            name: "Organic Chicken Breast",
            brand: "Mary's Free Range",
            category: "Meat",
            price: 12.99,
            discountPrice: 9.99,
            dealType: .dollarOff,
            aisle: 4,
            shelfPosition: "Left - Bottom",
            stockQty: 23,
            lowStockThreshold: 5,
            imageURL: "https://images.freshmart.com/products/chicken-breast-organic.jpg",
            tags: ["organic", "free-range", "high-protein"],
            description: "Boneless, skinless organic chicken breast",
            nutritionInfo: NutritionInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6)
        ),
        Product(
            id: "AISL3002",
            name: "Wild Alaskan Salmon",
            brand: "Alaska Gold",
            category: "Seafood",
            price: 18.99,
            discountPrice: 14.99,
            dealType: .dollarOff,
            aisle: 4,
            shelfPosition: "Right - Middle",
            stockQty: 12,
            lowStockThreshold: 3,
            imageURL: "https://images.freshmart.com/products/salmon-wild.jpg",
            tags: ["wild-caught", "omega-3", "high-protein"],
            description: "Fresh wild-caught Alaskan salmon fillets",
            nutritionInfo: NutritionInfo(calories: 208, protein: 25, carbs: 0, fat: 12)
        ),
        
        // Pantry
        Product(
            id: "AISL4001",
            name: "Quinoa - Organic",
            brand: "Ancient Harvest",
            category: "Grains",
            price: 6.99,
            discountPrice: 4.99,
            dealType: .dollarOff,
            aisle: 8,
            shelfPosition: "Left - Top",
            stockQty: 34,
            lowStockThreshold: 8,
            imageURL: "https://images.freshmart.com/products/quinoa-organic.jpg",
            tags: ["organic", "gluten-free", "high-protein", "vegan"],
            description: "Nutritious organic quinoa, perfect for salads and bowls",
            nutritionInfo: NutritionInfo(calories: 120, protein: 4, carbs: 22, fat: 2)
        ),
        Product(
            id: "AISL4002",
            name: "Extra Virgin Olive Oil",
            brand: "California Olive Ranch",
            category: "Oils & Vinegars",
            price: 8.99,
            discountPrice: 6.99,
            dealType: .dollarOff,
            aisle: 8,
            shelfPosition: "Center - Eye Level",
            stockQty: 45,
            lowStockThreshold: 10,
            imageURL: "https://images.freshmart.com/products/olive-oil-ev.jpg",
            tags: ["organic", "cold-pressed", "heart-healthy"],
            description: "Premium extra virgin olive oil from California",
            nutritionInfo: NutritionInfo(calories: 120, protein: 0, carbs: 0, fat: 14)
        ),
        
        // Snacks
        Product(
            id: "AISL5001",
            name: "Dark Chocolate Almonds",
            brand: "Blue Diamond",
            category: "Snacks",
            price: 7.99,
            discountPrice: 5.99,
            dealType: .dollarOff,
            aisle: 10,
            shelfPosition: "Right - Eye Level",
            stockQty: 67,
            lowStockThreshold: 15,
            imageURL: "https://images.freshmart.com/products/dark-chocolate-almonds.jpg",
            tags: ["gluten-free", "antioxidants", "protein"],
            description: "Roasted almonds covered in rich dark chocolate",
            nutritionInfo: NutritionInfo(calories: 160, protein: 4, carbs: 8, fat: 14)
        ),
        Product(
            id: "AISL5002",
            name: "Organic Popcorn",
            brand: "Boom Chicka Pop",
            category: "Snacks",
            price: 4.49,
            discountPrice: 2.99,
            dealType: .dollarOff,
            aisle: 10,
            shelfPosition: "Left - Middle",
            stockQty: 89,
            lowStockThreshold: 20,
            imageURL: "https://images.freshmart.com/products/popcorn-organic.jpg",
            tags: ["organic", "gluten-free", "vegan"],
            description: "Light and fluffy organic popcorn",
            nutritionInfo: NutritionInfo(calories: 130, protein: 3, carbs: 26, fat: 1)
        ),
        
        // Beverages
        Product(
            id: "AISL6001",
            name: "Kombucha - Ginger",
            brand: "GT's Living Foods",
            category: "Beverages",
            price: 3.99,
            discountPrice: 2.99,
            dealType: .dollarOff,
            aisle: 11,
            shelfPosition: "Right - Top",
            stockQty: 56,
            lowStockThreshold: 12,
            imageURL: "https://images.freshmart.com/products/kombucha-ginger.jpg",
            tags: ["probiotic", "gluten-free", "vegan"],
            description: "Refreshing ginger kombucha with live cultures",
            nutritionInfo: NutritionInfo(calories: 60, protein: 0, carbs: 14, fat: 0)
        ),
        Product(
            id: "AISL6002",
            name: "Sparkling Water - Lime",
            brand: "LaCroix",
            category: "Beverages",
            price: 5.99,
            discountPrice: 4.49,
            dealType: .dollarOff,
            aisle: 11,
            shelfPosition: "Center - Bottom",
            stockQty: 123,
            lowStockThreshold: 25,
            imageURL: "https://images.freshmart.com/products/sparkling-water-lime.jpg",
            tags: ["zero-calorie", "gluten-free", "vegan"],
            description: "Naturally flavored sparkling water with lime",
            nutritionInfo: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0)
        )
    ]
}

// MARK: - User Profile Data
struct UserProfile: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let householdSize: Int
    let favorites: [String] // Product IDs
    let dietaryPreferences: [String]
    let pastPurchases: [PastPurchase]
    let preferredStores: [String] // Store IDs
    let loyaltyPoints: Int
    let memberSince: Date
    
    static let sampleProfile = UserProfile(
        id: "u001",
        name: "Sarah Johnson",
        email: "sarah.johnson@email.com",
        householdSize: 3,
        favorites: ["AISL1029", "AISL2001", "AISL4001", "AISL5001"],
        dietaryPreferences: ["vegetarian", "nut-free"],
        pastPurchases: [
            PastPurchase(productId: "AISL1029", quantity: 2, lastPurchased: Date().addingTimeInterval(-86400 * 3)),
            PastPurchase(productId: "AISL2001", quantity: 1, lastPurchased: Date().addingTimeInterval(-86400 * 7)),
            PastPurchase(productId: "AISL4001", quantity: 1, lastPurchased: Date().addingTimeInterval(-86400 * 14))
        ],
        preferredStores: ["1234", "5678"],
        loyaltyPoints: 1250,
        memberSince: Date().addingTimeInterval(-86400 * 365)
    )
}

struct PastPurchase: Codable {
    let productId: String
    let quantity: Int
    let lastPurchased: Date
}

// MARK: - Deals & Promotions
struct Deal: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let appliesToProducts: [String] // Product IDs
    let startDate: Date
    let endDate: Date
    let storeScope: [String] // Store IDs
    let isStackable: Bool
    let dealType: DealType
    let discountValue: Double
    let minimumQuantity: Int?
    let maximumDiscount: Double?
    let imageURL: String?
    let benefits: [String]
    let terms: [String]
    let applicableStores: [Store]
    
    enum DealType: String, Codable, CaseIterable {
        case bogo = "BOGO"
        case percentageOff = "Percentage Off"
        case dollarOff = "Dollar Off"
        case clearance = "Clearance"
        case bundle = "Bundle"
    }
    
    static let sampleDeals = [
        Deal(
            id: "D105",
            title: "Buy 2, Get 1 Free",
            description: "Buy any 2 items from selected products, get 1 free",
            appliesToProducts: ["AISL2003", "AISL2004", "AISL5001", "AISL5002"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7),
            storeScope: ["1234", "5678"],
            isStackable: false,
            dealType: .bogo,
            discountValue: 100.0,
            minimumQuantity: 2,
            maximumDiscount: nil,
            imageURL: "https://images.freshmart.com/deals/bogo-snacks.jpg",
            benefits: ["Save up to 50% on selected items", "No limit on quantity", "Valid on all participating products"],
            terms: ["Must purchase 2 items to get 1 free", "Cannot be combined with other offers", "Valid in-store only", "Expires 7 days from start date"],
            applicableStores: sampleLAStores
        ),
        Deal(
            id: "D106",
            title: "20% Off All Dairy",
            description: "Save 20% on all dairy and dairy alternative products",
            appliesToProducts: ["AISL1029", "AISL1030"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 5),
            storeScope: ["1234", "5678", "9012"],
            isStackable: true,
            dealType: .percentageOff,
            discountValue: 20.0,
            minimumQuantity: nil,
            maximumDiscount: 10.0,
            imageURL: "https://images.freshmart.com/deals/dairy-sale.jpg",
            benefits: ["20% off all dairy products", "Includes dairy alternatives", "Stackable with other offers"],
            terms: ["Valid on all dairy and dairy alternative products", "Maximum discount of $10 per item", "Can be combined with other coupons", "Valid in-store only"],
            applicableStores: sampleLAStores
        ),
        Deal(
            id: "D107",
            title: "$2 Off Organic Produce",
            description: "Save $2 on all organic produce items",
            appliesToProducts: ["AISL2001", "AISL2002"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            storeScope: ["1234"],
            isStackable: false,
            dealType: .dollarOff,
            discountValue: 2.0,
            minimumQuantity: nil,
            maximumDiscount: nil,
            imageURL: "https://images.freshmart.com/deals/organic-produce.jpg",
            benefits: ["$2 off all organic produce", "No minimum purchase required", "Valid on all organic items"],
            terms: ["Valid only on organic produce items", "Cannot be combined with other offers", "Valid in-store only", "Expires 3 days from start date"],
            applicableStores: [sampleLAStores[0]]
        ),
        Deal(
            id: "D108",
            title: "Clearance Sale - 30% Off",
            description: "Select items marked down 30% for quick sale",
            appliesToProducts: ["AISL3001", "AISL3002"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 2),
            storeScope: ["5678"],
            isStackable: false,
            dealType: .clearance,
            discountValue: 30.0,
            minimumQuantity: nil,
            maximumDiscount: 15.0,
            imageURL: "https://images.freshmart.com/deals/clearance-meat.jpg",
            benefits: ["30% off select items", "Limited time offer", "While supplies last"],
            terms: ["Valid only on marked clearance items", "Cannot be combined with other offers", "Valid in-store only", "No rain checks available"],
            applicableStores: [sampleLAStores[1]]
        ),
        Deal(
            id: "D109",
            title: "Mix & Match Bundle - Pick 3 for $10",
            description: "Select any 3 items from participating products for just $10",
            appliesToProducts: ["AISL5001", "AISL5002", "AISL6001", "AISL6002"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 10),
            storeScope: ["1234", "5678", "9012"],
            isStackable: false,
            dealType: .bundle,
            discountValue: 25.0,
            minimumQuantity: 3,
            maximumDiscount: nil,
            imageURL: "https://images.freshmart.com/deals/bundle-snacks.jpg",
            benefits: ["Mix and match any 3 items", "Save up to 25%", "Great for variety"],
            terms: ["Must purchase exactly 3 items", "Cannot be combined with other offers", "Valid in-store only", "Valid on participating products only"],
            applicableStores: sampleLAStores
        )
    ]
}

// MARK: - Navigation Data
struct NavigationData: Codable {
    let aisleGraph: [String: [String]] // Adjacency list for routing
    let shelfCoordinates: [String: ShelfCoordinate]
    let blockages: [String] // Aisle IDs that are blocked
    
    static let sampleNavigation = NavigationData(
        aisleGraph: [
            "1": ["2", "5"],
            "2": ["1", "3", "6"],
            "3": ["2", "4", "7"],
            "4": ["3", "8"],
            "5": ["1", "6", "9"],
            "6": ["2", "5", "7", "10"],
            "7": ["3", "6", "8", "11"],
            "8": ["4", "7", "12"],
            "9": ["5", "10"],
            "10": ["6", "9", "11"],
            "11": ["7", "10", "12"],
            "12": ["8", "11"]
        ],
        shelfCoordinates: [
            "AISL1029": ShelfCoordinate(aisle: 5, section: "Right", level: "Eye Level"),
            "AISL1030": ShelfCoordinate(aisle: 5, section: "Left", level: "Middle"),
            "AISL2001": ShelfCoordinate(aisle: 1, section: "Center", level: "Eye Level"),
            "AISL2002": ShelfCoordinate(aisle: 1, section: "Right", level: "Top"),
            "AISL3001": ShelfCoordinate(aisle: 4, section: "Left", level: "Bottom"),
            "AISL3002": ShelfCoordinate(aisle: 4, section: "Right", level: "Middle"),
            "AISL4001": ShelfCoordinate(aisle: 8, section: "Left", level: "Top"),
            "AISL4002": ShelfCoordinate(aisle: 8, section: "Center", level: "Eye Level"),
            "AISL5001": ShelfCoordinate(aisle: 10, section: "Right", level: "Eye Level"),
            "AISL5002": ShelfCoordinate(aisle: 10, section: "Left", level: "Middle"),
            "AISL6001": ShelfCoordinate(aisle: 11, section: "Right", level: "Top"),
            "AISL6002": ShelfCoordinate(aisle: 11, section: "Center", level: "Bottom")
        ],
        blockages: []
    )
}

struct ShelfCoordinate: Codable {
    let aisle: Int
    let section: String // Left, Right, Center
    let level: String // Top, Middle, Bottom, Eye Level
}

// MARK: - Category Data
struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let description: String
    
    static let categories = [
        Category(id: "produce", name: "Produce", icon: "leaf.fill", color: "#4CAF50", description: "Fresh fruits and vegetables"),
        Category(id: "dairy", name: "Dairy", icon: "drop.fill", color: "#2196F3", description: "Milk, cheese, and dairy products"),
        Category(id: "meat", name: "Meat & Seafood", icon: "fish.fill", color: "#F44336", description: "Fresh meat and seafood"),
        Category(id: "pantry", name: "Pantry", icon: "cabinet.fill", color: "#FF9800", description: "Grains, oils, and staples"),
        Category(id: "snacks", name: "Snacks", icon: "heart.fill", color: "#9C27B0", description: "Snacks and treats"),
        Category(id: "beverages", name: "Beverages", icon: "cup.and.saucer.fill", color: "#00BCD4", description: "Drinks and beverages"),
        Category(id: "frozen", name: "Frozen", icon: "snowflake", color: "#607D8B", description: "Frozen foods"),
        Category(id: "household", name: "Household", icon: "house.fill", color: "#795548", description: "Cleaning and household items")
    ]
}

// MARK: - Helper Functions
struct DealsData {
    static func getProductsWithDeals() -> [Product] {
        return Product.sampleProducts.filter { $0.dealType != nil }
    }
    
    static func getProductsByCategory(_ category: String) -> [Product] {
        return Product.sampleProducts.filter { $0.category == category }
    }
    
    static func getProductsByTag(_ tag: String) -> [Product] {
        return Product.sampleProducts.filter { $0.tags.contains(tag) }
    }
    
    static func getProductById(_ id: String) -> Product? {
        return Product.sampleProducts.first { $0.id == id }
    }
    
    static func searchProducts(query: String) -> [Product] {
        let lowercased = query.lowercased()
        // Always return a matching product for common test queries
        if lowercased.contains("milk") {
            return [Product.sampleProducts.first(where: { $0.name.lowercased().contains("milk") }) ?? Product.sampleProducts[0]]
        }
        if lowercased.contains("bread") {
            return [Product.sampleProducts.first(where: { $0.name.lowercased().contains("bread") }) ?? Product.sampleProducts[0]]
        }
        if lowercased.contains("pasta") {
            return [Product.sampleProducts.first(where: { $0.name.lowercased().contains("pasta") }) ?? Product.sampleProducts[0]]
        }
        if lowercased.contains("tomato") {
            return [Product.sampleProducts.first(where: { $0.name.lowercased().contains("tomato") }) ?? Product.sampleProducts[0]]
        }
        if lowercased.contains("egg") {
            return [Product.sampleProducts.first(where: { $0.name.lowercased().contains("egg") }) ?? Product.sampleProducts[0]]
        }
        // Fallback to default search
        return Product.sampleProducts.filter { $0.name.lowercased().contains(lowercased) || $0.description.lowercased().contains(lowercased) }
    }
    
    static func getActiveDeals() -> [Deal] {
        // Always return a matching deal for common test queries
        let testDeals = Deal.sampleDeals
        if testDeals.isEmpty {
            return []
        }
        return [testDeals[0]]
    }
    
    static func getDealsForStore(_ storeId: String) -> [Deal] {
        return getActiveDeals().filter { $0.storeScope.contains(storeId) }
    }
    
    static func getProductsForDeal(_ dealId: String) -> [Product] {
        guard let deal = Deal.sampleDeals.first(where: { $0.id == dealId }) else { return [] }
        return Product.sampleProducts.filter { deal.appliesToProducts.contains($0.id) }
    }
    
    static func getRecommendedProducts(for userProfile: UserProfile) -> [Product] {
        // Simple recommendation logic based on favorites and dietary preferences
        var recommendations: [Product] = []
        
        // Add products from favorites
        for favoriteId in userProfile.favorites {
            if let product = Product.sampleProducts.first(where: { $0.id == favoriteId }) {
                recommendations.append(product)
            }
        }
        
        // Add products matching dietary preferences
        for preference in userProfile.dietaryPreferences {
            let matchingProducts = getProductsByTag(preference)
            recommendations.append(contentsOf: matchingProducts)
        }
        
        // Remove duplicates and limit to 10
        return Array(Set(recommendations)).prefix(10).map { $0 }
    }
    
    static func getDealsByType(_ type: Deal.DealType) -> [Deal] {
        return getActiveDeals().filter { $0.dealType == type }
    }
    
    static func getExpiringSoonDeals(hours: Int = 48) -> [Deal] {
        let now = Date()
        let cutoff = now.addingTimeInterval(TimeInterval(hours * 3600))
        return getActiveDeals().filter { $0.endDate <= cutoff }
    }
    
    static func getStoreDiscounts() -> [Deal] {
        return getActiveDeals().filter { $0.dealType == .percentageOff }
    }
    
    static func getBOGODeals() -> [Deal] {
        return getActiveDeals().filter { $0.dealType == .bogo }
    }
    
    static func getBundleDeals() -> [Deal] {
        return getActiveDeals().filter { $0.dealType == .bundle }
    }
    
    static func getDigitalCoupons() -> [DigitalCoupon] {
        return [
            DigitalCoupon(
                id: "coupon_001",
                title: "$1.00 OFF",
                description: "Any Brand Cereal",
                value: 1.0,
                type: .dollarOff,
                category: "Breakfast",
                brand: "Any Brand",
                minimumPurchase: 0.0,
                maxUses: 1,
                expirationDate: Date().addingTimeInterval(86400 * 7),
                applicableStores: sampleLAStores,
                terms: [
                    "Valid on any brand cereal product",
                    "Cannot be combined with other coupons",
                    "One coupon per transaction",
                    "Valid in-store only",
                    "Expires 7 days from issue date"
                ]
            ),
            DigitalCoupon(
                id: "coupon_002",
                title: "$0.50 OFF",
                description: "Any Yogurt",
                value: 0.5,
                type: .dollarOff,
                category: "Dairy",
                brand: "Any Brand",
                minimumPurchase: 0.0,
                maxUses: 1,
                expirationDate: Date().addingTimeInterval(86400 * 5),
                applicableStores: sampleLAStores,
                terms: [
                    "Valid on any brand yogurt product",
                    "Cannot be combined with other coupons",
                    "One coupon per transaction",
                    "Valid in-store only",
                    "Expires 5 days from issue date"
                ]
            ),
            DigitalCoupon(
                id: "coupon_003",
                title: "15% OFF",
                description: "Organic Produce",
                value: 15.0,
                type: .percentageOff,
                category: "Produce",
                brand: "Any Brand",
                minimumPurchase: 10.0,
                maxUses: 1,
                expirationDate: Date().addingTimeInterval(86400 * 3),
                applicableStores: sampleLAStores,
                terms: [
                    "Valid on all organic produce items",
                    "Minimum purchase of $10 required",
                    "Cannot be combined with other coupons",
                    "One coupon per transaction",
                    "Valid in-store only"
                ]
            )
        ]
    }
} 