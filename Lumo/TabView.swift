//
//  TabBarView.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            // HOME TAB: StoreMapView
            StoreMapView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // BROWSE TAB: BrowseView
            BrowseView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Browse")
                }

            // EXPLORE TAB: ExploreView
            ExploreView()
                .tabItem {
                    Image(systemName: "safari")
                    Text("Explore")
                }

            // CART TAB: ShoppingCartView
            if appState.shoppingCart.totalItems > 0 {
                ShoppingCartView()
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Cart")
                    }
                    .badge(appState.shoppingCart.totalItems)
            } else {
                ShoppingCartView()
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Cart")
                    }
            }

            // PROFILE TAB: Optional
            StoreMapView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .previewLayout(.sizeThatFits)
            .background(Color.black)
            .environmentObject(AppState()) // Provide AppState for preview

    }
}
