// BrowseView.swift
// Lumo
//
// Created by Tony on 6/18/25.
//

import SwiftUI

// MARK: - SmartSuggestion Model (Existing)
struct SmartSuggestion: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    // No explicit icon property for now, assuming emoji or system icons if needed
}

// MARK: - GroceryItemCard Helper View (Existing - no changes needed here)
struct GroceryItemCard: View {
    let item: GroceryItem
    let customOutlineColor: Color
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("Price: \(item.price, specifier: "%.2f")")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                Text("Aisle: \(item.aisle)")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Button(action: {
                appState.shoppingCart.addItem(item)
                print("Added \(item.name) to cart. Total items: \(appState.shoppingCart.totalItems)")
            }) {
                Image(systemName: "cart.fill.badge.plus")
                    .font(.title2)
                    .foregroundColor(customOutlineColor)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(customOutlineColor, lineWidth: 1)
        )
    }
}


// MARK: - BrowseView
struct BrowseView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var smartSuggestions: [SmartSuggestion] = []
    @State private var isLoadingSuggestions: Bool = false
    @State private var suggestionError: String? = nil

    // NEW: State for random quick suggestion titles
    @State private var randomQuickSuggestionTitles: [String] = []

    // Chat history for Gemini API to maintain context for "new" suggestions
    @State private var chatHistory: [[String: Any]] = []

    // Custom color for the outline, 00F0C0
    private let customCyanColor = Color(red: 0/255, green: 240/255, blue: 192/255)

    // Computed property for the store name to display
    var displayedStoreInfo: String {
        if let selectedStore = appState.selectedStoreName {
            let components = selectedStore.components(separatedBy: " - ")
            if components.count == 2 {
                return "\(components[0]) - \(components[1])"
            }
            return selectedStore
        }
        return "Select a Store"
    }

    // Computed property to filter grocery items based on debounced search text
    var filteredGroceryItems: [GroceryItem] {
        if debouncedSearchText.isEmpty {
            return []
        } else {
            let lowercasedSearchText = debouncedSearchText.lowercased()
            return sampleGroceryItems.filter { item in
                item.name.lowercased().contains(lowercasedSearchText) ||
                item.description.lowercased().contains(lowercasedSearchText) ||
                item.aisle.lowercased().contains(lowercasedSearchText)
            }
        }
    }

    // Define adaptive columns for the Quick Suggestion Buttons grid (Existing)
    private var quickButtonColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 150), spacing: 10),
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Store Name - City Header
                Text(displayedStoreInfo)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for items...", text: $searchText)
                        .foregroundColor(.blue)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 8)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .background(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(customCyanColor.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal)
                .onChange(of: searchText) { newValue in
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        if newValue == self.searchText {
                            self.debouncedSearchText = newValue
                        }
                    }
                }

                // Conditional display based on search text
                if debouncedSearchText.isEmpty {
                    // Quick Suggestion Buttons (Now using randomQuickSuggestionTitles)
                    LazyVGrid(columns: quickButtonColumns, spacing: 10) {
                        ForEach(randomQuickSuggestionTitles, id: \.self) { title in
                            QuickButton(title: title, customOutlineColor: customCyanColor)
                        }
                    }
                    .padding(.horizontal)

                    // Smart Suggestions Header (Existing)
                    HStack {
                        Text("Smart Suggestions")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            Task {
                                await fetchSmartSuggestions(isRefresh: true)
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(customCyanColor)
                        }
                    }
                    .padding(.horizontal)

                    // Smart Suggestions List (Existing)
                    if isLoadingSuggestions {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: customCyanColor))
                            .scaleEffect(1.5)
                            .padding()
                    } else if let error = suggestionError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else if smartSuggestions.isEmpty {
                        Text("No smart suggestions available. Tap Refresh!")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(smartSuggestions) { suggestion in
                                    SmartSuggestionCard(suggestion: suggestion, customOutlineColor: customCyanColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Display Filtered Grocery Items (Existing)
                    if filteredGroceryItems.isEmpty {
                        Text("No items found matching \"\(debouncedSearchText)\".")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredGroceryItems) { item in
                                    GroceryItemCard(item: item, customOutlineColor: customCyanColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                // Start Route Button (Existing)
                Button(action: {
                    print("Start Route tapped!")
                    // Implement navigation or action to start route
                }) {
                    HStack {
                        Image(systemName: "chevron.backward.2")
                        Text("Start Route")
                        Image(systemName: "chevron.forward.2")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [customCyanColor, Color.cyan]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                    .shadow(color: customCyanColor.opacity(0.6), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
        .onAppear {
            if smartSuggestions.isEmpty && searchText.isEmpty {
                Task {
                    await fetchSmartSuggestions(isRefresh: false)
                }
            }
            // NEW: Populate random quick suggestions when the view appears
            populateRandomQuickSuggestions()
        }
    }

    // MARK: - Helper Function to populate random quick suggestions
    private func populateRandomQuickSuggestions() {
        // Ensure you have enough sample data to pick from
        guard sampleGroceryItems.count >= 4 else {
            print("Not enough sample grocery items to populate 4 quick suggestions.")
            randomQuickSuggestionTitles = sampleGroceryItems.map { $0.name } // Fallback: use all available
            return
        }

        var selectedTitles: Set<String> = []
        while selectedTitles.count < 4 {
            if let randomItem = sampleGroceryItems.randomElement() {
                selectedTitles.insert(randomItem.name)
            }
        }
        randomQuickSuggestionTitles = Array(selectedTitles)
    }


    // MARK: - Gemini API Call Function
    func fetchSmartSuggestions(isRefresh: Bool) async {
        isLoadingSuggestions = true
        suggestionError = nil

        let prompt: String
        if isRefresh && !chatHistory.isEmpty {
            // Modified prompt for refresh to ask for a list of ingredients
            prompt = "Give me 3 *different and new* smart suggestions for grocery items or meal ideas, distinct from what you've suggested before. For each suggestion, provide the 'description' as a **bulleted list of the minimum necessary key ingredients or components needed**, without any introductory or concluding sentences. Focus on practical, common grocery needs. Ensure the response is in JSON format matching the provided schema, with 'title' and 'description' for each suggestion."
        } else {
            // Modified prompt for initial fetch to ask for a list of ingredients
            prompt = "Generate 3 smart, creative, and practical suggestions for grocery items or meal ideas. For each suggestion, provide the 'description' as a **bulleted list of the necessary key ingredients or components needed**, without any introductory or concluding sentences. Provide the response as a JSON array of objects, where each object has 'title' (String) and 'description' (String) properties. For example: [{\"title\": \"Taco Night\", \"description\": \"- Tortillas\\n- Ground beef\\n- Salsa\\n- Shredded cheese\\n- Lettuce\\n- Jalapeños\"}]"
        }

        // Add the new user prompt to chat history
        chatHistory.append(["role": "user", "parts": [["text": prompt]]])

        do {
            let payload: [String: Any] = [
                "contents": chatHistory,
                "generationConfig": [
                    "responseMimeType": "application/json",
                    "responseSchema": [
                        "type": "ARRAY",
                        "items": [
                            "type": "OBJECT",
                            "properties": [
                                "title": ["type": "STRING"],
                                "description": ["type": "STRING"] // Description is still a String
                            ],
                            "required": ["title", "description"]
                        ]
                    ]
                ]
            ]

            guard let apiKey = APIKeyManager.shared.geminiAPIKey else {
                throw NSError(domain: "BrowseView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Gemini API Key is not configured."])
            }

            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
                throw URLError(.badServerResponse, userInfo: ["response": responseString])
            }

            let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            if let candidates = jsonResponse?["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {

                guard let jsonData = text.data(using: .utf8) else {
                    throw NSError(domain: "BrowseView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data."])
                }
                let newSuggestions = try JSONDecoder().decode([SmartSuggestion].self, from: jsonData)

                // Update chat history with the model's response for future context
                chatHistory.append(["role": "model", "parts": [["text": text]]])

                DispatchQueue.main.async {
                    self.smartSuggestions = newSuggestions
                }
            } else {
                throw NSError(domain: "BrowseView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unexpected API response structure."])
            }

        } catch {
            print("Failed to fetch smart suggestions: \(error)")
            DispatchQueue.main.async {
                self.suggestionError = error.localizedDescription
            }
        }
        DispatchQueue.main.async {
            self.isLoadingSuggestions = false
        }
    }
}

// BrowseView.swift (or QuickButton.swift if you separated it)

// MARK: - QuickButton Helper View
struct QuickButton: View {
    let title: String
    let customOutlineColor: Color
    @EnvironmentObject var appState: AppState // Access AppState

    var body: some View {
        Button(action: {
            print("\(title) button tapped!")
            // Find the corresponding grocery item and add it to the cart
            if let item = sampleGroceryItems.first(where: { $0.name == title }) {
                appState.shoppingCart.addItem(item)
                print("Added \(item.name) to cart. Total items: \(appState.shoppingCart.totalItems)")
            }
        }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(customOutlineColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - SmartSuggestionCard Helper View (Existing - no changes needed)
struct SmartSuggestionCard: View {
    let suggestion: SmartSuggestion
    let customOutlineColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "arrow.forward.circle.fill")
                .font(.title2)
                .foregroundColor(customOutlineColor)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(customOutlineColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider (Existing)
struct BrowseView_Previews: PreviewProvider {
    static var previews: some View {
        BrowseView()
            .environmentObject(AppState())
    }
}
