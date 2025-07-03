//
//  TabView.swift
//  Lumo
//
//  Created by Tony on 6/18/25. Edited by Ethan on 7/3/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView {
            // EXPLORE TAB
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
            
            // BROWSE TAB
            BrowseView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Browse")
                }
            
            // DEALS TAB
            DealsView()
                .tabItem {
                    Image(systemName: "tag")
                    Text("Deals")
                }
            
            // GROCERY LIST TAB: GroceryListView
            if appState.groceryList.totalItems > 0 {
                GroceryListView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Grocery List")
                    }
                    .badge(appState.groceryList.totalItems)
            } else {
                GroceryListView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Grocery List")
                    }
            }
            
            // MAP TAB
            StoreMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            // AI ASSISTANT TAB
            ChatbotView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Assistant")
                }
            
            // PROFILE TAB
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .accentColor(Color.lumoGreen)
        .environmentObject(appState)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
