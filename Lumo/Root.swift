//
//  Root.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
//
//  RootView.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import SwiftUI
import MapKit // Required for CLLocationCoordinate2D for sample data if not globally available
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigationPath = NavigationPath() // Controls the NavigationStack

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // The very first view in our navigation flow
            LumoWelcomeView(navigationPath: $navigationPath) // Pass NavigationPath down
                .navigationDestination(for: String.self) { destination in
                    // Define how to present different views based on String identifiers
                    if destination == "StoreFinder" {
                        StoreFinderView(navigationPath: $navigationPath) // Pass NavigationPath down
                            .navigationTitle("")
                            .toolbar(.hidden, for: .navigationBar)
                    } else if destination == "StoreSelection" {
                        StoreSelectionView(stores: sampleLAStores) // No binding needed here, AppState handles dismissal
                            .navigationTitle("")
                            .toolbar(.hidden, for: .navigationBar)
                    } else if destination == "TabBar" {
                        TabBarView()
                            .toolbar(.hidden, for: .navigationBar) // TabBarView usually doesn't need a navigation bar
                    }
                }
                .toolbar(.hidden, for: .navigationBar) // Hide the initial navigation bar for LumoWelcomeView
        }
        // This observer listens for changes in selectedStoreName and triggers navigation
        .onReceive(appState.$selectedStoreName) { newStoreName in
            if newStoreName != nil {
                // If a store is selected, clear the current stack and push TabBarView
                navigationPath = NavigationPath() // Clears all views from the stack
                navigationPath.append("TabBar")   // Pushes TabBarView onto the now empty stack
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState()) // Provide AppState for preview
    }
}
