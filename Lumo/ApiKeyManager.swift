//
//  ApiKeyManager.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation

class APIKeyManager {
    static let shared = APIKeyManager() // Singleton instance

    // MARK: - Gemini API Key
    var geminiAPIKey: String? {
        // MARK: IMPORTANT: Replace "YOUR_GEMINI_API_KEY_HERE" with your actual Gemini API key.
        // For security, do NOT commit your actual API key directly to version control.
        // Consider using Xcode build settings (.xcconfig files) or environment variables
        // for better security in production apps.
        return "AIzaSyDe8142DC8z5aAZ9nnYkhB2v5PsawHGCa4"
    }
    
    // MARK: - Spoonacular API Key
    var spoonacularAPIKey: String? {
        // Try multiple paths to load the API key
        let possiblePaths = [
            "/Users/ethanzhang/Desktop/lumo/spoonacular.key",  // Absolute path
            "spoonacular.key",  // Relative to current directory
            Bundle.main.path(forResource: "spoonacular", ofType: "key") ?? ""  // App bundle
        ]
        
        for path in possiblePaths {
            if let key = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
               !key.isEmpty && !key.hasPrefix("#") {
                print("[APIKeyManager] Spoonacular API key loaded successfully from: \(path)")
                return key
            }
        }
        
        print("[APIKeyManager] ERROR: No Spoonacular API key found. Tried paths: \(possiblePaths)")
        print("[APIKeyManager] Please create a spoonacular.key file with your API key from https://spoonacular.com/food-api")
        return nil
    }

    private init() {} // Private initializer to ensure singleton usage
}
