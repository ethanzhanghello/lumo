//
//  LumoWelcomeView.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import SwiftUI

struct LumoWelcomeView: View {
    // Binding to the NavigationPath from RootView to control navigation
    @Binding var navigationPath: NavigationPath

    var body: some View {
        // Removed NavigationStack from here
        ZStack {
            // Background color
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Enlarged logo with shiny edge effect
                ZStack {
                    Image("Lumologotest")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 300) // Increased size
                        // Outer glowing shadow
                        .shadow(color: Color.white.opacity(0.7), radius: 36, x: 0, y: 0)
                    // Shiny edge overlay (assuming it's handled by Lumologotest or CSS/other means)
                }
                .frame(width: 180, height: 180)
                .padding(.bottom, 8)

                ZStack{
                    // App Name
                    Image("lumo") // Make sure this asset is in your project
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250) // Increased size
                        .padding(.bottom, 8)
                        .padding(.leading, 30)
                }
                .frame(width: 150, height: 90)

                // Subtitle
                VStack(spacing: 4) {
                    Text("Navigate smarter.")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Sign in or create an account")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 12)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Navigate to Create Account
                        navigationPath.append("CreateAccount")
                    }) {
                        Text("Create an Account")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.13, green: 0.98, blue: 0.88))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        // Navigate to Login
                        navigationPath.append("Login")
                    }) {
                        Text("Log in")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }

                    Button(action: {
                        // Append a string identifier to the navigation path
                        // This will trigger the .navigationDestination in RootView
                        navigationPath.append("TabBar")
                    }) {
                        Text("Continue as guest")
                            .font(.footnote)
                            .underline()
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        // Removed .navigationDestination and .navigationBarHidden/BackButtonHidden
        // as they are handled by the parent NavigationStack in RootView
    }
}

// Preview
struct LumoWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, provide a dummy binding for navigationPath
        LumoWelcomeView(navigationPath: .constant(NavigationPath()))
            .environmentObject(AppState()) // Also provide AppState for consistency
    }
}
