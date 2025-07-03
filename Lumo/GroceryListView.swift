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
    @State private var showingCheckoutAlert = false
    @State private var checkoutResult: CheckoutResult?
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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Search
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            
                            Spacer()
                            
                            Text("Grocery List")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search or add items...", text: $searchText)
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    if !searchText.isEmpty {
                                        addItemFromSearch()
                                    }
                                }
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
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
                                
                                // Control Buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingGroupedView.toggle()
                                    }) {
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
                                        showingRoutePreview = true
                                    }) {
                                        HStack {
                                            Image(systemName: "map")
                                            Text("Route")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.lumoGreen)
                                        .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        showingSmartSuggestions = true
                                    }) {
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
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // Grocery Items List
                    if appState.groceryList.isEmpty {
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
                            
                            Button(action: {
                                showingSmartSuggestions = true
                            }) {
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
                    } else {
                        if showingGroupedView {
                            GroupedGroceryListView()
                        } else {
                            FlatGroceryListView()
                        }
                    }
                    
                    // Checkout Button
                    if !appState.groceryList.isEmpty {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingCheckoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                    Text("Checkout")
                                    Spacer()
                                    Text("$\(appState.groceryList.totalCost, specifier: "%.2f")")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.lumoGreen)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.black)
                    }
                }
            }
            .navigationBarItems(trailing: EmptyView())
        }
        .alert("Confirm Checkout", isPresented: $showingCheckoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Checkout") {
                checkoutResult = appState.groceryList.checkout()
                showingOrderConfirmation = true
            }
        } message: {
            Text("Are you sure you want to checkout with \(appState.groceryList.totalItems) items for $\(appState.groceryList.totalCost, specifier: "%.2f")?")
        }
        .alert("Order Confirmation", isPresented: $showingOrderConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let result = checkoutResult {
                Text(result.message)
            }
        }
        .sheet(isPresented: $showingRoutePreview) {
            RoutePreviewView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingSmartSuggestions) {
            SmartSuggestionsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["Check out my grocery list on Lumo!", URL(string: "https://www.lumoapp.com")!])
        }
        .overlay(
            // Undo Toast
            VStack {
                if showingUndoToast {
                    HStack {
                        Text("Item removed")
                            .foregroundColor(.white)
                        Button("Undo") {
                            if let item = removedItem {
                                appState.groceryList.addItem(item.item, quantity: item.quantity)
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
                            withAnimation {
                                showingUndoToast = false
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 100)
        )
    }
    
    private func addItemFromSearch() {
        if let foundItem = sampleGroceryItems.first(where: { $0.name.lowercased().contains(searchText.lowercased()) }) {
            appState.groceryList.addItem(foundItem)
            searchText = ""
        }
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
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removedItem = groceryItem
                            appState.groceryList.removeItem(groceryItem.item)
                            withAnimation {
                                showingUndoToast = true
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct GroupedGroceryListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: String?
    
    var groupedItems: [String: [GroceryListItem]] {
        Dictionary(grouping: appState.groceryList.groceryItems) { item in
            item.item.category
        }
    }
    
    var body: some View {
        List {
            ForEach(Array(groupedItems.keys.sorted()), id: \.self) { category in
                Section(header: 
                    HStack {
                        Text(category)
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(groupedItems[category]?.count ?? 0) items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                ) {
                    ForEach(groupedItems[category] ?? [], id: \.id) { groceryItem in
                        GroceryItemCard(groceryItem: groceryItem)
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
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
        HStack(spacing: 12) {
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
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .foregroundColor(.white.opacity(0.6))
                        )
                    
                    // Item Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(groceryItem.item.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .strikethrough(isChecked)
                        
                        if !groceryItem.item.brand.isEmpty {
                            Text(groceryItem.item.brand)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack {
                            Text("Aisle \(groceryItem.item.aisle)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            if groceryItem.item.hasDeal {
                                Text("2 for $5")
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
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quantity Controls (separate from item details)
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        print("Decrement button tapped for \(groceryItem.item.name), current quantity: \(groceryItem.quantity)")
                        animateQuantityChange {
                            if groceryItem.quantity > 1 {
                                print("Updating quantity from \(groceryItem.quantity) to \(groceryItem.quantity - 1)")
                                appState.groceryList.updateQuantity(for: groceryItem.item, to: groceryItem.quantity - 1)
                            } else {
                                print("Cannot decrement below 1")
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
                        .frame(minWidth: 30)
                        .offset(y: quantityOffset)
                        .opacity(quantityOpacity)
                    
                    Button(action: {
                        print("Increment button tapped for \(groceryItem.item.name), current quantity: \(groceryItem.quantity)")
                        animateQuantityChange {
                            print("Updating quantity from \(groceryItem.quantity) to \(groceryItem.quantity + 1)")
                            appState.groceryList.updateQuantity(for: groceryItem.item, to: groceryItem.quantity + 1)
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
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
                appState.groceryList.addItem(item)
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        GroceryListView()
            .environmentObject(AppState())
    }
} 