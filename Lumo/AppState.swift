//
//  AppState.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/2/25 and 7/3/25.
//

import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedStore: Store?
    @Published var groceryList: GroceryList
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        self.groceryList = GroceryList()
        
        // Observe grocery list changes
        groceryList.$groceryItems
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
