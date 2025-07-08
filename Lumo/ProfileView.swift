//
//  ProfileView.swift
//  Lumo
//
//  Created by Ethan on 2025-07-03.
//

import SwiftUI
import PhotosUI // Required for photo picker

struct ProfileView: View {
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image? = Image(systemName: "person.crop.circle.fill") // Default image
    @State private var fullName: String = "Rhashad Lawery"
    @State private var email: String = "RL@Rhashad.com"
    @State private var passwordVisible: Bool = false
    @State private var passwordField: String = "************" // Placeholder for password
    @State private var allergyFiltersEnabled: Bool = false
    @State private var accessibilityEnabled: Bool = false

    // Custom color for the slider
    let lumoGreen = Color(red: 0/255, green: 240/255, blue: 192/255)

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Profile Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // Profile Picture Section
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Group {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(lumoGreen, lineWidth: 2))
                                .animation(.easeOut, value: profileImage) // Smooth animation for image change
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(lumoGreen)
                                .animation(.easeOut, value: profileImage)
                        }
                    }
                }
                .onChange(of: selectedImage) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }

                // Form Fields
                VStack(alignment: .leading, spacing: 16) {
                    Text("Full name")
                        .foregroundColor(.white)
                        .font(.headline)
                    TextField("", text: $fullName)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(lumoGreen) // Cursor color

                    Text("Email")
                        .foregroundColor(.white)
                        .font(.headline)
                    TextField("", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(lumoGreen)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Text("Password")
                        .foregroundColor(.white)
                        .font(.headline)
                    HStack {
                        if passwordVisible {
                            TextField("", text: $passwordField)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(lumoGreen)
                        } else {
                            SecureField("", text: $passwordField)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(lumoGreen)
                        }
                        Button(action: {
                            passwordVisible.toggle()
                            // Add animation for eye icon
                        }) {
                            Image(systemName: passwordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(lumoGreen)
                                .animation(.easeInOut, value: passwordVisible)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding(.horizontal)

                // Toggles
                VStack(spacing: 16) {
                    Toggle(isOn: $allergyFiltersEnabled) {
                        Text("Allergy / Dietary Filters")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: lumoGreen)) // Apply custom color to slider
                    .animation(.easeInOut, value: allergyFiltersEnabled)

                    Toggle(isOn: $accessibilityEnabled) {
                        Text("Accessibility")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: lumoGreen)) // Apply custom color to slider
                    .animation(.easeInOut, value: accessibilityEnabled)
                }
                .padding(.horizontal)

                Spacer()

                // Log out Button
                Button(action: {
                    // Action for Log out
                    print("Log out tapped")
                }) {
                    Text("Log out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lumoGreen, lineWidth: 2) // Border color
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true) // Hide default navigation bar to use custom back button
        }
    }
}

#Preview {
    ProfileView()
}
