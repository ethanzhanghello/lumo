//
//  ItemDetailView.swift
//  Lumo
//
//  Created by Ethan on 7/2/25.
//

import SwiftUI

struct ItemDetailView: View {
    let item: GroceryItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Int = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Item Image
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "bag.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 60))
                            )
                            .padding(.horizontal)
                        
                        // Item Info
                        VStack(alignment: .leading, spacing: 16) {
                            // Name and Price
                            HStack {
                                Text(item.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("$\(item.price, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.lumoGreen)
                            }
                            
                            // Description
                            Text(item.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(nil)
                            
                            // Aisle Location
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color.lumoGreen)
                                Text("Aisle: \(item.aisle)")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Quantity Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Quantity")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Button(action: {
                                        if quantity > 1 {
                                            quantity -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(quantity > 1 ? Color.lumoGreen : .gray)
                                    }
                                    .disabled(quantity <= 1)
                                    
                                    Text("\(quantity)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(minWidth: 50)
                                    
                                    Button(action: {
                                        quantity += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color.lumoGreen)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Total Price
                            HStack {
                                Text("Total:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("$\(item.price * Double(quantity), specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.lumoGreen)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add to Cart Button
                        Button(action: {
                            if let selectedStore = appState.selectedStore {
                                appState.groceryList.addItem(item, store: selectedStore, quantity: quantity)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                    .font(.title3)
                                Text("Add to Cart")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lumoGreen)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Share") {
                    // TODO: Implement share functionality
                }
                .foregroundColor(.white)
            )
        }
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(item: sampleGroceryItems[0])
            .environmentObject(AppState())
    }
} 