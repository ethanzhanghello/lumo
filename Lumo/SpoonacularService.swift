//
//  SpoonacularService.swift
//  Lumo
//
//  Created by Ethan on 7/4/25.
//

import Foundation

// MARK: - Spoonacular API Models
struct SpoonacularRecipe: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String?
    let imageType: String?
    let servings: Int
    let readyInMinutes: Int
    let license: String?
    let sourceName: String?
    let sourceUrl: String?
    let spoonacularSourceUrl: String?
    let healthScore: Double?
    let spoonacularScore: Double?
    let pricePerServing: Double?
    let analyzedInstructions: [AnalyzedInstruction]?
    let cheap: Bool?
    let creditsText: String?
    let cuisines: [String]?
    let dairyFree: Bool?
    let diets: [String]?
    let gaps: String?
    let glutenFree: Bool?
    let instructions: String?
    let ketogenic: Bool?
    let lowFodmap: Bool?
    let occasions: [String]?
    let sustainable: Bool?
    let vegan: Bool?
    let vegetarian: Bool?
    let veryHealthy: Bool?
    let veryPopular: Bool?
    let whole30: Bool?
    let weightWatcherSmartPoints: Int?
    let dishTypes: [String]?
    let extendedIngredients: [SpoonacularIngredient]?
    let summary: String?
    let winePairing: WinePairing?
    
    // Convert to our Recipe model
    func toRecipe() -> Recipe {
        let ingredients = extendedIngredients?.map { $0.toRecipeIngredient() } ?? []
        let instructions = analyzedInstructions?.flatMap { $0.steps.map { $0.step } } ?? []
        
        return Recipe(
            id: "SPOON_\(id)",
            name: title,
            description: summary?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? "",
            category: getCategory(),
            difficulty: getDifficulty(),
            prepTime: readyInMinutes / 2,
            cookTime: readyInMinutes / 2,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            nutritionInfo: NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0),
            tags: dishTypes ?? [],
            imageURL: image,
            rating: spoonacularScore ?? 0,
            reviewCount: 0,
            dietaryInfo: getDietaryInfo(),
            estimatedCost: (pricePerServing ?? 0) / 100.0, // Convert from cents
            cuisine: cuisines?.first ?? "Unknown",
            author: sourceName ?? "Spoonacular"
        )
    }
    
    private func getCategory() -> RecipeCategory {
        if let dishTypes = dishTypes {
            if dishTypes.contains("breakfast") { return .breakfast }
            if dishTypes.contains("lunch") { return .lunch }
            if dishTypes.contains("dinner") { return .dinner }
            if dishTypes.contains("dessert") { return .dessert }
            if dishTypes.contains("snack") { return .snack }
            if dishTypes.contains("appetizer") { return .appetizer }
            if dishTypes.contains("soup") { return .soup }
            if dishTypes.contains("salad") { return .salad }
            if dishTypes.contains("pasta") { return .pasta }
            if dishTypes.contains("meat") { return .meat }
            if dishTypes.contains("seafood") { return .seafood }
        }
        return .dinner
    }
    
    private func getDifficulty() -> RecipeDifficulty {
        if readyInMinutes <= 15 { return .easy }
        if readyInMinutes <= 45 { return .medium }
        return .hard
    }
    
    private func getDietaryInfo() -> DietaryInfo {
        return DietaryInfo(
            isVegetarian: vegetarian ?? false,
            isVegan: vegan ?? false,
            isGlutenFree: glutenFree ?? false,
            isDairyFree: dairyFree ?? false,
            isNutFree: true, // Spoonacular doesn't provide this
            isKeto: ketogenic ?? false,
            isPaleo: false, // Spoonacular doesn't provide this
            allergens: []
        )
    }
}

struct SpoonacularIngredient: Codable {
    let id: Int?
    let aisle: String?
    let amount: Double?
    let unit: String?
    let name: String?
    let original: String?
    let originalName: String?
    let meta: [String]?
    let image: String?
    
    func toRecipeIngredient() -> RecipeIngredient {
        return RecipeIngredient(
            name: name ?? originalName ?? "Unknown",
            amount: amount ?? 0,
            unit: unit ?? "",
            aisle: getAisleNumber(),
            estimatedPrice: 0, // Will be calculated separately
            notes: original
        )
    }
    
    private func getAisleNumber() -> Int {
        guard let aisle = aisle else { return 1 }
        switch aisle.lowercased() {
        case "produce": return 1
        case "spices": return 2
        case "pasta and rice": return 3
        case "meat": return 4
        case "dairy": return 5
        case "canned and jarred": return 6
        case "baking": return 7
        case "frozen": return 8
        case "beverages": return 9
        default: return 1
        }
    }
}

struct AnalyzedInstruction: Codable {
    let name: String?
    let steps: [Step]
}

struct Step: Codable {
    let number: Int?
    let step: String
    let ingredients: [Ingredient]?
    let equipment: [Equipment]?
}

struct Ingredient: Codable {
    let id: Int?
    let name: String?
    let localizedName: String?
    let image: String?
}

struct Equipment: Codable {
    let id: Int?
    let name: String?
    let localizedName: String?
    let image: String?
}

struct WinePairing: Codable {
    let pairedWines: [String]?
    let pairingText: String?
    let productMatches: [ProductMatch]?
}

struct ProductMatch: Codable {
    let id: Int?
    let title: String?
    let description: String?
    let price: String?
    let imageUrl: String?
    let averageRating: Double?
    let ratingCount: Int?
    let score: Double?
    let link: String?
}

// MARK: - Search Response Models
struct SpoonacularSearchResponse: Codable {
    let results: [SpoonacularRecipe]?
    let offset: Int?
    let number: Int?
    let totalResults: Int?
}

struct SpoonacularNutritionResponse: Codable {
    let calories: String?
    let carbs: String?
    let fat: String?
    let protein: String?
    let bad: [NutritionBad]?
    let good: [NutritionGood]?
    let expiring: [NutritionExpiring]?
    let missed: [NutritionMissed]?
}

struct NutritionBad: Codable {
    let name: String?
    let amount: Double?
    let indented: Bool?
    let percentOfDailyNeeds: Double?
}

struct NutritionGood: Codable {
    let name: String?
    let amount: Double?
    let indented: Bool?
    let percentOfDailyNeeds: Double?
}

struct NutritionExpiring: Codable {
    let name: String?
    let amount: Double?
    let indented: Bool?
    let percentOfDailyNeeds: Double?
}

struct NutritionMissed: Codable {
    let name: String?
    let amount: Double?
    let indented: Bool?
    let percentOfDailyNeeds: Double?
}

// MARK: - Spoonacular Service
class SpoonacularService: ObservableObject {
    static let shared = SpoonacularService()
    
    private let baseURL = "https://api.spoonacular.com/recipes"
    private var apiKey: String = ""
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        if let key = APIKeyManager.shared.spoonacularAPIKey {
            self.apiKey = key
        } else {
            print("[SpoonacularService] ERROR: No Spoonacular API key found. Please create a spoonacular.key file with your API key.")
        }
    }
    
    // MARK: - Recipe Search
    func searchRecipes(query: String, diet: String? = nil, cuisine: String? = nil, maxReadyTime: Int? = nil, offset: Int = 0, number: Int = 10) async -> [Recipe] {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var components = URLComponents(string: "\(baseURL)/complexSearch")!
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "number", value: "\(number)"),
            URLQueryItem(name: "addRecipeInformation", value: "true"),
            URLQueryItem(name: "fillIngredients", value: "true"),
            URLQueryItem(name: "instructionsRequired", value: "true")
        ]
        
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        
        if let maxReadyTime = maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: "\(maxReadyTime)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            lastError = "Invalid URL"
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return []
            }
            
            let searchResponse = try JSONDecoder().decode(SpoonacularSearchResponse.self, from: data)
            return searchResponse.results?.map { $0.toRecipe() } ?? []
            
        } catch {
            lastError = "Search failed: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Recipe Details
    func getRecipeDetails(id: Int) async -> Recipe? {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "\(baseURL)/\(id)/information?apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            lastError = "Invalid URL"
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return nil
            }
            
            let recipe = try JSONDecoder().decode(SpoonacularRecipe.self, from: data)
            return recipe.toRecipe()
            
        } catch {
            lastError = "Failed to get recipe details: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Nutrition Analysis
    func analyzeNutrition(ingredients: [String]) async -> SpoonacularNutritionResponse? {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let ingredientsString = ingredients.joined(separator: "\n")
        
        var components = URLComponents(string: "\(baseURL)/analyze")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        guard let url = components.url else {
            lastError = "Invalid URL"
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["ingredientList": ingredientsString]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return nil
            }
            
            return try JSONDecoder().decode(SpoonacularNutritionResponse.self, from: data)
            
        } catch {
            lastError = "Nutrition analysis failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Random Recipes
    func getRandomRecipes(tags: [String] = [], number: Int = 10) async -> [Recipe] {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var components = URLComponents(string: "\(baseURL)/random")!
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: "\(number)")
        ]
        
        if !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            lastError = "Invalid URL"
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return []
            }
            
            let recipes = try JSONDecoder().decode([SpoonacularRecipe].self, from: data)
            return recipes.map { $0.toRecipe() }
            
        } catch {
            lastError = "Failed to get random recipes: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Similar Recipes
    func getSimilarRecipes(id: Int, number: Int = 5) async -> [Recipe] {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "\(baseURL)/\(id)/similar?apiKey=\(apiKey)&number=\(number)"
        
        guard let url = URL(string: urlString) else {
            lastError = "Invalid URL"
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return []
            }
            
            let recipes = try JSONDecoder().decode([SpoonacularRecipe].self, from: data)
            return recipes.map { $0.toRecipe() }
            
        } catch {
            lastError = "Failed to get similar recipes: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Recipe by Ingredients
    func findRecipesByIngredients(ingredients: [String], ranking: Int = 2, ignorePantry: Bool = true) async -> [Recipe] {
        guard !apiKey.isEmpty else {
            lastError = "Spoonacular API key not configured"
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let ingredientsString = ingredients.joined(separator: ",")
        
        var components = URLComponents(string: "\(baseURL)/findByIngredients")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "ingredients", value: ingredientsString),
            URLQueryItem(name: "ranking", value: "\(ranking)"),
            URLQueryItem(name: "ignorePantry", value: ignorePantry ? "true" : "false")
        ]
        
        guard let url = components.url else {
            lastError = "Invalid URL"
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid HTTP response"
                return []
            }
            
            guard httpResponse.statusCode == 200 else {
                lastError = "HTTP \(httpResponse.statusCode)"
                return []
            }
            
            // This endpoint returns a different format, so we need to get full recipe details
            let recipeSummaries = try JSONDecoder().decode([RecipeSummary].self, from: data)
            
            // Get full recipe details for each summary
            var fullRecipes: [Recipe] = []
            for summary in recipeSummaries {
                if let fullRecipe = await getRecipeDetails(id: summary.id) {
                    fullRecipes.append(fullRecipe)
                }
            }
            
            return fullRecipes
            
        } catch {
            lastError = "Failed to find recipes by ingredients: \(error.localizedDescription)"
            return []
        }
    }
}

// MARK: - Recipe Summary (for findByIngredients endpoint)
struct RecipeSummary: Codable {
    let id: Int
    let title: String
    let image: String?
    let imageType: String?
    let usedIngredientCount: Int?
    let missedIngredientCount: Int?
    let missedIngredients: [MissedIngredient]?
    let usedIngredients: [UsedIngredient]?
    let unusedIngredients: [UnusedIngredient]?
    let likes: Int?
}

struct MissedIngredient: Codable {
    let id: Int?
    let amount: Double?
    let unit: String?
    let unitLong: String?
    let unitShort: String?
    let aisle: String?
    let name: String?
    let original: String?
    let originalName: String?
    let meta: [String]?
    let image: String?
}

struct UsedIngredient: Codable {
    let id: Int?
    let amount: Double?
    let unit: String?
    let unitLong: String?
    let unitShort: String?
    let aisle: String?
    let name: String?
    let original: String?
    let originalName: String?
    let meta: [String]?
    let image: String?
}

struct UnusedIngredient: Codable {
    let id: Int?
    let amount: Double?
    let unit: String?
    let unitLong: String?
    let unitShort: String?
    let aisle: String?
    let name: String?
    let original: String?
    let originalName: String?
    let meta: [String]?
    let image: String?
} 