//
//  AppState.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedStoreName: String? = nil
    @Published var shoppingCart: ShoppingCart
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.shoppingCart = ShoppingCart()
        
        // Observe shopping cart changes and trigger UI updates
        shoppingCart.$cartItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
