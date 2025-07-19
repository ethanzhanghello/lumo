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
            // Explore Tab
            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Explore")
            }
            
            // Store Map Tab
            NavigationStack {
                StoreMapView()
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text("Map")
            }
            
            // Grocery List Tab
            NavigationStack {
                GroceryListView()
            }
            .tabItem {
                Image(systemName: "cart")
                Text("List")
            }
            
            
            // MEAL PLANNING TAB
            MealPlanningView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Meal Plan")
                }
            
            
            // AI ASSISTANT TAB
            ChatbotView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Lumo Assistant")
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
