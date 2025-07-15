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
    @StateObject var authViewModel = AuthViewModel()

    init() {
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Root()
                .environmentObject(appState)
                .environmentObject(authViewModel)
        }
    }
}


