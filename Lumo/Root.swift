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
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            // Check authentication status on appear
            Task {
                await authViewModel.checkAuthStatus()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
