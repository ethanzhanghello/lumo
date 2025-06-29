//
//  AppState.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
import Foundation

class AppState: ObservableObject {
    @Published var selectedStoreName: String? = nil
    @Published var shoppingCart: ShoppingCart // Add this line

    init() {
        self.shoppingCart = ShoppingCart() // Initialize the shopping cart
    }
}
