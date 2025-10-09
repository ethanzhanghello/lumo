//
//  GroceryListView.swift
//  Lumo
//
//  Created by Ethan on 7/1/25. Edited by Ethan on 7/2/25, 7/3/25, and 7/3/25.
//

import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingOrderConfirmation = false
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var showingGroupedView = false
    @State private var showingRoutePreview = false
    @State private var showingShareSheet = false
    @State private var showingSmartSuggestions = false
    @State private var removedItem: GroceryListItem?
    @State private var showingUndoToast = false
    @State private var selectedCategory: String?
    @State private var showingStoreMap = false
    @State private var showingStoreSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                mainContent
            }
            .navigationBarItems(trailing: EmptyView())
            .alert("List Saved", isPresented: $showingOrderConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your grocery list has been saved to shopping history.")
            }
            .sheet(isPresented: $showingStoreMap) {
                StoreMapView().environmentObject(appState)
            }
            .sheet(isPresented: $showingSmartSuggestions) {
                SmartSuggestionsView().environmentObject(appState)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: ["Check out my grocery list on Lumo!", URL(string: "https://www.lumoapp.com")!])
            }
            .sheet(isPresented: $showingStoreSelection) {
                NavigationView {
                    StoreSelectionView(stores: sampleLAStores)
                        .environmentObject(appState)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingStoreSelection = false
                                }
                                .foregroundColor(.gray)
                            }
                        }
                }
            }

            .overlay(undoToastOverlay)
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            if appState.groceryList.isEmpty {
                emptyListSection
            } else {
                itemsSection
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                // Removed xmark close button
                Spacer()
                Text("Grocery List")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search or add items...", text: $searchText)
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !searchText.isEmpty { addItemFromSearch() }
                    }
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            // List Summary and Controls
            if !appState.groceryList.isEmpty {
                summarySection
            }
        }
        .padding(.top)
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(appState.groceryList.totalItems) items")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Estimated time: \(appState.groceryList.estimatedTimeMinutes) min")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("$\(appState.groceryList.totalCost, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.lumoGreen)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: { showingGroupedView.toggle() }) {
                        HStack {
                            Image(systemName: showingGroupedView ? "list.bullet" : "folder")
                            Text(showingGroupedView ? "Flat View" : "Grouped")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                    Button(action: { 
                        if appState.selectedStore != nil {
                            showingStoreMap = true
                        } else {
                            showingStoreSelection = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "map")
                            Text("Map Route")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.lumoGreen)
                        .cornerRadius(8)
                    }
                    Button(action: { showingSmartSuggestions = true }) {
                        HStack {
                            Image(systemName: "lightbulb")
                            Text("Suggestions")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Enhanced Route Preview
            if let selectedStore = appState.selectedStore {
                QuickRoutePreview(
                    groceryList: appState.groceryList,
                    store: selectedStore
                )
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Select a store to see route preview")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Button("Choose Store") {
                        showingStoreSelection = true
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var emptyListSection: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Your grocery list is empty")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            Text("Add some items to get started")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Button(action: { showingSmartSuggestions = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Common Items")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.lumoGreen)
                .cornerRadius(8)
            }
            Spacer()
        }
    }
    
    private var itemsSection: some View {
        Group {
            if showingGroupedView {
                GroupedGroceryListView()
            } else {
                FlatGroceryListView()
            }
            saveListButton
        }
    }
    
    private var saveListButton: some View {
        Button(action: {
            // Save the current grocery list to shopping history
            Task {
                // Save to history (simplified - just show confirmation)
                showingOrderConfirmation = true
            }
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Save Grocery List")
                Spacer()
                Text("\(appState.groceryList.totalItems) items")
            }
            .foregroundColor(.black)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.lumoGreen)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    

    
    private var undoToastOverlay: some View {
        VStack {
            if showingUndoToast {
                HStack {
                    Text("Item removed").foregroundColor(.white)
                    Button("Undo") {
                        if let item = removedItem {
                            appState.groceryList.addItem(item.item, store: item.store, quantity: item.quantity)
                            showingUndoToast = false
                        }
                    }
                    .foregroundColor(.lumoGreen)
                }
                .padding()
                .background(Color.gray.opacity(0.9))
                .cornerRadius(8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation { showingUndoToast = false }
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 100)
    }
    
    private func addItemFromSearch() {
        if let foundItem = sampleGroceryItems.first(where: { $0.name.lowercased().contains(searchText.lowercased()) }), let store = appState.selectedStore {
            appState.groceryList.addItem(foundItem, store: store)
            triggerHapticFeedback()
            searchText = ""
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct FlatGroceryListView: View {
    @EnvironmentObject var appState: AppState
    @State private var removedItem: GroceryListItem?
    @State private var showingUndoToast = false
    
    var body: some View {
        List {
            ForEach(appState.groceryList.groceryItems) { groceryItem in
                GroceryItemCard(groceryItem: groceryItem)
                    .environmentObject(appState)
                    .padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .listRowBackground(Color.clear)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = appState.groceryList.groceryItems[index]
                    appState.groceryList.removeItem(item.item, store: item.store)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct GroupedGroceryListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: String?
    
    var groupedItems: [Store: [String: [GroceryListItem]]] {
        Dictionary(grouping: appState.groceryList.groceryItems, by: { $0.store }).mapValues { items in
            Dictionary(grouping: items, by: { $0.item.category })
        }
    }
    
    var body: some View {
        List {
            ForEach(Array(groupedItems.keys), id: \.id) { store in
                Section(header:
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(store.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.lumoGreen)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Text("\(groupedItems[store]?.values.flatMap { $0 }.count ?? 0) items")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(store.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: true, vertical: false)
                        Rectangle()
                            .fill(Color(red: 0, green: 0.94, blue: 0.75))
                            .frame(height: 1)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                ) {
                    ForEach(Array(groupedItems[store]!.keys.sorted()), id: \.self) { category in
                        // Category header is just text, no line
                        Section(header:
                            HStack {
                                Spacer()
                                Text("\(groupedItems[store]![category]?.count ?? 0) items")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .listRowInsets(EdgeInsets())
                        ) {
                            let items = groupedItems[store]![category] ?? []
                            ForEach(items, id: \.id) { groceryItem in
                                GroceryItemCard(groceryItem: groceryItem)
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let item = items[index]
                                    appState.groceryList.removeItem(item.item, store: item.store)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct GroceryItemCard: View {
    let groceryItem: GroceryListItem
    @EnvironmentObject var appState: AppState
    @State private var quantityOffset: CGFloat = 0
    @State private var quantityOpacity: Double = 1
    @State private var minusButtonScale: CGFloat = 1
    @State private var plusButtonScale: CGFloat = 1
    @State private var showingItemDetail = false
    @State private var isChecked = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Checkbox
            Button(action: {
                withAnimation(.spring()) {
                    isChecked.toggle()
                }
            }) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .lumoGreen : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Item Image and Details (tappable area for item details)
            Button(action: {
                showingItemDetail = true
            }) {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.title3)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(groceryItem.item.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                            .strikethrough(isChecked)
                        if !groceryItem.item.brand.isEmpty {
                            Text(groceryItem.item.brand)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        // Horizontal info row for aisle, store, deal
                        HStack(alignment: .center, spacing: 8) {
                            Text("Aisle \(groceryItem.item.aisle)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            Text(groceryItem.store.name)
                                .font(.caption2)
                                .foregroundColor(.lumoGreen)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(minWidth: 60, maxWidth: 120, alignment: .leading)
                            if groceryItem.item.hasDeal {
                                Text("2 for $5")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .cornerRadius(4)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quantity Controls and Price
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        animateQuantityChange {
                            if groceryItem.quantity > 1 {
                                appState.groceryList.updateQuantity(for: groceryItem.item, store: groceryItem.store, to: groceryItem.quantity - 1)
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(groceryItem.quantity > 1 ? Color.lumoGreen : .gray)
                            .font(.title3)
                            .scaleEffect(minusButtonScale)
                    }
                    .disabled(groceryItem.quantity <= 1)
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(groceryItem.quantity)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 28)
                        .offset(y: quantityOffset)
                        .opacity(quantityOpacity)
                    
                    Button(action: {
                        animateQuantityChange {
                            appState.groceryList.updateQuantity(for: groceryItem.item, store: groceryItem.store, to: groceryItem.quantity + 1)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.lumoGreen)
                            .font(.title3)
                            .scaleEffect(plusButtonScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Text("$\(groceryItem.totalPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.lumoGreen)
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(14)
        .background(Color.gray.opacity(0.13))
        .cornerRadius(14)
        .opacity(isChecked ? 0.6 : 1.0)
        .sheet(isPresented: $showingItemDetail) {
            ItemDetailView(item: groceryItem.item)
                .environmentObject(appState)
        }
    }
    
    private func animateQuantityChange(action: @escaping () -> Void) {
        // Button animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            minusButtonScale = 1.2
            plusButtonScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                minusButtonScale = 1
                plusButtonScale = 1
            }
        }
        
        // Quantity animation
        withAnimation(.easeInOut(duration: 0.15)) {
            quantityOffset = 10
            quantityOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                quantityOffset = 0
                quantityOpacity = 1
            }
        }
    }
}

struct RoutePreviewView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.lumoGreen)
                
                Text("In-Store Route")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Optimized route for \(appState.groceryList.totalItems) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Estimated time: \(appState.groceryList.estimatedTimeMinutes) minutes")
                    }
                    
                    HStack {
                        Image(systemName: "figure.walk")
                        Text("Total distance: ~0.8 miles")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Button("Start Navigation") {
                    // TODO: Implement actual navigation
                    dismiss()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.lumoGreen)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Route Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SmartSuggestionsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let commonItems = [
        GroceryItem(name: "Milk", description: "2% Organic Milk", price: 4.99, category: "Dairy", aisle: 3, brand: "Organic Valley"),
        GroceryItem(name: "Bread", description: "Whole Wheat Bread", price: 3.49, category: "Bakery", aisle: 2, brand: "Dave's Killer Bread"),
        GroceryItem(name: "Eggs", description: "Large Brown Eggs", price: 5.99, category: "Dairy", aisle: 3, brand: "Vital Farms"),
        GroceryItem(name: "Bananas", description: "Organic Bananas", price: 2.99, category: "Produce", aisle: 1, brand: ""),
        GroceryItem(name: "Chicken Breast", description: "Boneless Skinless", price: 12.99, category: "Meat", aisle: 4, brand: "Perdue")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Smart Suggestions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Common items you might need:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(commonItems) { item in
                        SuggestionCard(item: item)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SuggestionCard: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .lineLimit(2)
            
            Text(item.brand.isEmpty ? item.description : item.brand)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("$\(item.price, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.lumoGreen)
            
            Button("Add") {
                if let selectedStore = appState.selectedStore {
                    appState.groceryList.addItem(item, store: selectedStore)
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.lumoGreen)
            .cornerRadius(6)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Map Integration Components

struct QuickRoutePreview: View {
    let groceryList: GroceryList
    let store: Store
    @StateObject private var routeManager = RouteOptimizationManager.shared
    @State private var estimatedStats: RouteStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route Preview")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let stats = estimatedStats {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(stats.estimatedTimeMinutes) min")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("\(Int(stats.totalDistance))ft")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let stats = estimatedStats {
                VStack(spacing: 8) {
                    // Route Steps Preview
                    HStack(spacing: 8) {
                        ForEach(Array(stats.aisleOrder.enumerated()), id: \.offset) { index, aisleId in
                            HStack(spacing: 4) {
                                if index > 0 {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(getAisleName(aisleId))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // Route Efficiency Indicator
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Optimized for logical shopping order")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(stats.stopsCount) stops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Calculating optimal route...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            calculateRoutePreview()
        }
        .onChange(of: groceryList.groceryItems) { _ in
            calculateRoutePreview()
        }
    }
    
    private func calculateRoutePreview() {
        Task {
            do {
                // Generate a quick route preview without storing it
                let route = try await routeManager.generateRoute(
                    for: groceryList,
                    in: store,
                    optimizationStrategy: .logicalOrder
                )
                
                await MainActor.run {
                    estimatedStats = RouteStats(
                        totalDistance: route.totalDistance,
                        estimatedTimeMinutes: route.estimatedTime,
                        stopsCount: route.waypoints.count,
                        aisleOrder: route.waypoints.map { $0.aisleId ?? "Unknown" }
                    )
                }
            } catch {
                print("Failed to calculate route preview: \(error)")
            }
        }
    }
    
    private func getAisleName(_ aisleId: String) -> String {
        switch aisleId {
        case "PRODUCE": return "Produce"
        case "MEAT": return "Meat"
        case "DAIRY": return "Dairy"
        case "FROZEN": return "Frozen"
        case "BAKERY": return "Bakery"
        case "A1": return "Aisle 1"
        case "A2": return "Aisle 2"
        case "A3": return "Aisle 3"
        default: return aisleId
        }
    }
}

struct RouteStats {
    let totalDistance: Double
    let estimatedTimeMinutes: Int
    let stopsCount: Int
    let aisleOrder: [String]
}



struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
            .environmentObject(AppState())
    }
} 
