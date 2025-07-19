// BrowseView.swift
// Lumo
//
// Created by Tony on 6/18/25.
//

import SwiftUI

// Remove the duplicate SmartSuggestion struct - it's already defined in GroceryItems.swift

// Remove the GroceryItemCard struct definition from this file entirely.
// Replace usages of GroceryItemCard(item: item, customOutlineColor: ...) with BrowseItemCard(item: item)
// Define a simple BrowseItemCard below:

struct BrowseItemCard: View {
    let item: GroceryItem
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack {
                    Text("Aisle \(item.aisle)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    if item.hasDeal, let deal = item.dealDescription {
                        Text(deal)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            Text("$\(item.price, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.lumoGreen)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
        if let selectedStore = appState.selectedStore {
            return selectedStore.name
        }
        return "No Store Selected"
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
                String(item.aisle).lowercased().contains(lowercasedSearchText)
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
                                    BrowseItemCard(item: item)
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

        // For now, let's use the suggestion engine from AppState instead of the API
        // This will be more reliable and consistent with the rest of the app
        let suggestions = appState.getSmartSuggestions()
        
        DispatchQueue.main.async {
            self.smartSuggestions = suggestions
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
            if let item = sampleGroceryItems.first(where: { $0.name == title }), let selectedStore = appState.selectedStore {
                appState.groceryList.addItem(item, store: selectedStore)
                print("Added \(item.name) to grocery list. Total items: \(appState.groceryList.totalItems)")
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

// MARK: - SmartSuggestionCard Helper View (Updated to work with GroceryItems.swift SmartSuggestion)
struct SmartSuggestionCard: View {
    let suggestion: SmartSuggestion
    let customOutlineColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(suggestion.reason)
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
