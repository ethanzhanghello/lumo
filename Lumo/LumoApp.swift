//
//  LumoApp.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct LumoApp: App {
    @StateObject var appState = AppState()
    init() {
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        // Set selected and unselected item color
        let selectedColor = UIColor(red: 0/255, green: 240/255, blue: 192/255, alpha: 1)
        let unselectedColor = UIColor(red: 0/255, green: 240/255, blue: 192/255, alpha: 0.4) // Lower opacity
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
