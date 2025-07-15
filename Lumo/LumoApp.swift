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
    @State private var glowOpacity: Double = 0.08
    @State private var glowRadius: CGFloat = 20
    @State private var logoOpacity: Double = 1.0
    @State private var nextScreenOpacity: Double = 0.0 // New state for the next screen

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
                            .opacity(nextScreenOpacity) // Fade in the next screen
                    } else if isLoggedIn {
                        MainTabView()
                            .environmentObject(appState)
                            .environmentObject(authViewModel)
                            .opacity(nextScreenOpacity) // Fade in the next screen
                    } else {
                        RootView()
                            .environmentObject(appState)
                            .environmentObject(authViewModel)
                            .opacity(nextScreenOpacity) // Fade in the next screen
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
                            .animation(.easeInOut(duration: 1.2), value: glowOpacity)
                            .animation(.easeInOut(duration: 1.2), value: glowRadius)
                        
                        // Animated Logo
                        Image("LumoLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 260)
                            .opacity(logoOpacity) // Apply opacity to the logo
                            .animation(.easeInOut(duration: 1.0), value: logoOpacity) // Animate opacity change
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
                
                // Splash animation: Glow increases, then fades out
                withAnimation(.easeInOut(duration: 1.2)) {
                    glowOpacity = 0.8
                    glowRadius = 90
                    logoOpacity = 1.0 // Make logo visible
                }
                
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s glow up
                
                // Now start fading out the glow and logo, and fading in the next screen
                withAnimation(.easeInOut(duration: 0.8)) {
                    glowOpacity = 0.0
                    glowRadius = 30
                    logoOpacity = 0.0 // Fade out the logo
                    nextScreenOpacity = 1.0 // Fade in the next screen
                }
                
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s fade out
                showSplash = false // Remove splash only after fade out
            }
            .onReceive(authViewModel.$isAuthenticated) { authenticated in
                isLoggedIn = authenticated
            }
        }
    }
}
