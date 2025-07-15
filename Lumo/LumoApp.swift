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
    @State private var isLoggedIn: Bool = false
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showSplash: Bool = true
    @State private var splashOpacity: Double = 1.0
    @State private var glowOpacity: Double = 0.08 // Start with minimal glow
    @State private var glowRadius: CGFloat = 20

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
            ZStack {
                Group {
                    if showOnboarding {
                        OnboardingView(showOnboarding: $showOnboarding)
                    } else if isLoggedIn {
                        MainTabView()
                            .environmentObject(appState)
                            .environmentObject(authViewModel)
                    } else {
                        RootView()
                            .environmentObject(appState)
                            .environmentObject(authViewModel)
                    }
                }
                // Splash overlay
                if showSplash {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        // Animated Glow
                        Circle()
                            .fill(Color(red: 0/255, green: 240/255, blue: 192/255))
                            .frame(width: 340, height: 340)
                            .blur(radius: glowRadius)
                            .opacity(glowOpacity)
                            .animation(.easeInOut(duration: 1.1), value: glowOpacity)
                            .animation(.easeInOut(duration: 1.1), value: glowRadius)
                        Image("LumoLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 260)
                            // No opacity animation, always fully visible
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .task {
                // Async session check
                if let session = try? await SupabaseManager.shared.client.auth.session, session != nil {
                    isLoggedIn = true
                }
                // Splash animation: Glow increases, then fades out, logo always visible
                withAnimation(.easeInOut(duration: 1.1)) {
                    glowOpacity = 0.8
                    glowRadius = 90
                }
                try? await Task.sleep(nanoseconds: 1_100_000_000) // 1.1s glow up
                withAnimation(.easeInOut(duration: 0.9)) {
                    glowOpacity = 0.0
                }
                try? await Task.sleep(nanoseconds: 900_000_000) // 0.9s fade out
                showSplash = false // Remove splash only after fade out
            }
            .onReceive(authViewModel.$isAuthenticated) { authenticated in
                isLoggedIn = authenticated
            }
        }
    }
}
