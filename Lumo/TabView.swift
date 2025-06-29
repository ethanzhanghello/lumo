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

            // BROWSE TAB: Replace with your browse view
            StoreMapView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Lumo")
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
