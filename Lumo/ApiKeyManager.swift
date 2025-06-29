//
//  ApiKeyManager.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation

class APIKeyManager {
    static let shared = APIKeyManager() // Singleton instance

    // You can replace "YOUR_GEMINI_API_KEY_HERE" with your actual key.
    // For production apps, consider more secure ways to manage keys
    // like environment variables, .xcconfig files, or fetching from a backend.
    var geminiAPIKey: String? {
        // MARK: IMPORTANT: Replace "YOUR_GEMINI_API_KEY_HERE" with your actual Gemini API key.
        // For security, do NOT commit your actual API key directly to version control.
        // Consider using Xcode build settings (.xcconfig files) or environment variables
        // for better security in production apps.
        return "AIzaSyDe8142DC8z5aAZ9nnYkhB2v5PsawHGCa4"
    }

    private init() {} // Private initializer to ensure singleton usage
}
