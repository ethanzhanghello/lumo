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
            ZStack {
                Color.black.ignoresSafeArea()
                
                // TEMPORARILY SKIP AUTHENTICATION - GO DIRECTLY TO MAIN APP
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
                    .opacity(showSplash ? 0 : 1)
                
                // Splash screen
                if showSplash {
                    SplashScreenView(opacity: $splashOpacity, glowOpacity: $glowOpacity, glowRadius: $glowRadius)
                        .onAppear {
                            // Animate splash screen
                            withAnimation(.easeInOut(duration: 1.5)) {
                                glowOpacity = 0.3
                                glowRadius = 40
                            }
                            
                            // Hide splash screen after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct SplashScreenView: View {
    @Binding var opacity: Double
    @Binding var glowOpacity: Double
    @Binding var glowRadius: CGFloat
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo with glow effect
                Image("LumoLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.blue.opacity(glowOpacity), radius: glowRadius)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowOpacity)
                
                Text("Lumo")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10)
                
                Text("Smart Grocery Shopping")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .opacity(opacity)
    }
}
