//
//  LoginView.swift
//  Lumo
//
//  Created by Tony on 7/11/25.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var navigationPath: NavigationPath
    
    @State private var saveLogin = false
    @State private var agreedToTerms = false
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo icon
                Image("Lumologotest")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 40)

                // Welcome text
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Log in")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))

                // Email and password fields
                VStack(spacing: 14) {
                    TextField("Email", text: $authViewModel.email)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#00F0C0"), lineWidth: 1)
                        )

                    ZStack(alignment: .trailing) {
                        if isPasswordVisible {
                            TextField("Password", text: $authViewModel.password)
                        } else {
                            SecureField("Password", text: $authViewModel.password)
                        }
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(Color(hex: "#00F0C0"))
                        }
                        .padding(.trailing, 12)
                    }
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#00F0C0"), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)

                // Toggle sliders
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $saveLogin) {
                        Text("Save login info on this device")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .tint(Color(hex: "#00F0C0"))

                    Toggle(isOn: $agreedToTerms) {
                        HStack {
                            Text("I agree to")
                                .foregroundColor(.white)
                            Button(action: {}) {
                                Text("Terms & Privacy")
                                    .foregroundColor(Color(hex: "#00F0C0"))
                            }
                        }
                        .font(.subheadline)
                    }
                    .tint(Color(hex: "#00F0C0"))
                }
                .padding(.horizontal, 24)

                // Login button
                Button(action: {
                    Task {
                        await login()
                    }
                }) {
                    Text("Log in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#00F0C0"))
                        .foregroundColor(.black)
                        .font(.headline)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
                .padding(.horizontal, 24)
                
                // Show error if login fails
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                // Footer link
                Button(action: {
                    // Navigate to create account
                    navigationPath.append("CreateAccount")
                }) {
                    Text("Need to sign up?")
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }

                Spacer()
            }
        }
    }
    
    private func login() async {
        // Validate form
        guard !authViewModel.email.isEmpty else {
            authViewModel.errorMessage = "Please enter your email"
            return
        }
        
        guard !authViewModel.password.isEmpty else {
            authViewModel.errorMessage = "Please enter your password"
            return
        }
        
        guard agreedToTerms else {
            authViewModel.errorMessage = "Please agree to Terms & Privacy"
            return
        }
        
        // Attempt to sign in
        await authViewModel.signIn()
        
        // If successful, navigate to store finder
        if authViewModel.errorMessage == nil {
            // Clear the navigation stack and go to store finder
            navigationPath.removeLast()
            navigationPath.append("TabBar")
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(navigationPath: .constant(NavigationPath()))
            .preferredColorScheme(.dark)
    }
}
