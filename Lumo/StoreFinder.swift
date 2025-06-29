//
//  StoreFinder.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import Foundation
import SwiftUI

struct StoreFinderView: View {
    // Binding to the NavigationPath from RootView to control navigation
    @Binding var navigationPath: NavigationPath

    var body: some View {
        // Removed NavigationStack from here
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()
                ZStack{
                    // Logo
                    Image("Lumologotest")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 250) // Increased size
                        .shadow(color: Color.cyan.opacity(0.7), radius: 16)
                        .padding(.bottom, 8)
                }
                .frame(width: 180, height: 180)
                .padding(.bottom, 8)

                // Main Text
                VStack(spacing: 0) {
                    Text("Let's find")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                    Text("your store")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }

                // Subtitle
                Text("Turn on location to\nauto-detect your store")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Use location action
                        print("Use My Location tapped")
                    }) {
                        Text("Use My Location")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0/255, green: 240/255, blue: 192/255))
                            .cornerRadius(10)
                    }

                    Button(action: {
                        // Append a string identifier to the navigation path
                        // This will trigger the .navigationDestination for "StoreSelection" in RootView
                        navigationPath.append("StoreSelection")
                    }) {
                        Text("Enter Store Manually")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        // Removed .navigationDestination and .navigationBarHidden/BackButtonHidden
        // as they are handled by the parent NavigationStack in RootView
    }
}

// Preview
struct StoreFinderView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, provide a dummy binding for navigationPath
        StoreFinderView(navigationPath: .constant(NavigationPath()))
    }
}
