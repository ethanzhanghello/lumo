//
//  Root.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
            } else {
                LoginView(navigationPath: $navigationPath)
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // Authentication status is automatically managed by AuthViewModel
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
