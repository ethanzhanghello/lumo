//
//  ProfileView.swift
//  Lumo
//
//  Created by Ethan on 2025-07-03.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.lumoGreen)
                    .padding(.top, 40)
                Text("Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Welcome to your profile page!")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
} 