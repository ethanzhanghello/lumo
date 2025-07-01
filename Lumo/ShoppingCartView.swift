//
//  ShoppingCartView.swift
//  Lumo
//
//  Created by Ethan on 7/1/25.
//

import SwiftUI

struct ShoppingCartView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckoutAlert = false
    @State private var checkoutResult: CheckoutResult?
    @State private var showingOrderConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
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
                            
                            Text("Shopping Cart")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Invisible button for balance
                            Button(action: {}) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.clear)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Cart Summary
                        if !appState.shoppingCart.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(appState.shoppingCart.totalItems) items")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("Estimated time: \(appState.shoppingCart.estimatedTimeMinutes) min")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("$\(appState.shoppingCart.totalCost, specifier: "%.2f")")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.lumoGreen)
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
                    
                    // Cart Items List
                    if appState.shoppingCart.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "cart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Your cart is empty")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("Add some items to get started")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(appState.shoppingCart.cartItems) { cartItem in
                                    CartItemRow(cartItem: cartItem)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    
                    // Checkout Button
                    if !appState.shoppingCart.isEmpty {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingCheckoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                    Text("Checkout")
                                    Spacer()
                                    Text("$\(appState.shoppingCart.totalCost, specifier: "%.2f")")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.lumoGreen)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                appState.shoppingCart.clearCart()
                            }) {
                                Text("Clear Cart")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.bottom)
                        }
                        .background(Color.black)
                    }
                }
            }
        }
        .alert("Confirm Checkout", isPresented: $showingCheckoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Checkout") {
                checkoutResult = appState.shoppingCart.checkout()
                showingOrderConfirmation = true
            }
        } message: {
            Text("Are you sure you want to checkout with \(appState.shoppingCart.totalItems) items for $\(appState.shoppingCart.totalCost, specifier: "%.2f")?")
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
    }
}

struct CartItemRow: View {
    let cartItem: CartItem
    @EnvironmentObject var appState: AppState
    @State private var quantity: Int
    
    init(cartItem: CartItem) {
        self.cartItem = cartItem
        self._quantity = State(initialValue: cartItem.quantity)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Item Image Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.white.opacity(0.6))
                )
            
            // Item Details
            VStack(alignment: .leading, spacing: 4) {
                Text(cartItem.item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(cartItem.item.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                Text("Aisle: \(cartItem.item.aisle)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Quantity Controls
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        if quantity > 1 {
                            quantity -= 1
                            appState.shoppingCart.updateQuantity(for: cartItem.item, to: quantity)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(quantity > 1 ? Color.lumoGreen : .gray)
                            .font(.title3)
                    }
                    .disabled(quantity <= 1)
                    
                    Text("\(quantity)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        quantity += 1
                        appState.shoppingCart.updateQuantity(for: cartItem.item, to: quantity)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.lumoGreen)
                            .font(.title3)
                    }
                }
                
                Text("$\(cartItem.totalPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.lumoGreen)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                appState.shoppingCart.removeItem(cartItem.item)
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct ShoppingCartView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingCartView()
            .environmentObject(AppState())
    }
} 