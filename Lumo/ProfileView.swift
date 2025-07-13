//
//  ProfileView.swift
//  Lumo
//
//  Created by Ethan on 2025-07-03.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image? = Image(systemName: "person.crop.circle.fill")
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var passwordVisible: Bool = false
    @State private var passwordField: String = "************" // Masked, not editable
    @State private var allergyFiltersEnabled: Bool = false
    @State private var accessibilityEnabled: Bool = false
    @State private var isLoading: Bool = true
    @State private var showSaveConfirmation: Bool = false
    @State private var showingLogoutAlert: Bool = false

    let lumoGreen = Color(red: 0/255, green: 240/255, blue: 192/255)

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Profile Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // Profile Picture Section (unchanged)
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Group {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(lumoGreen, lineWidth: 2))
                                .animation(.easeOut, value: profileImage)
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
                    TextField("", text: $fullName, onCommit: saveProfile)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(lumoGreen)

                    Text("Email")
                        .foregroundColor(.white)
                        .font(.headline)
                    TextField("", text: .constant(email))
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .accentColor(lumoGreen)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(true)

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
                                .disabled(true)
                        } else {
                            SecureField("", text: $passwordField)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(lumoGreen)
                                .disabled(true)
                        }
                        Button(action: {
                            passwordVisible.toggle()
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
                    .toggleStyle(SwitchToggleStyle(tint: lumoGreen))
                    .animation(.easeInOut, value: allergyFiltersEnabled)
                    .onChange(of: allergyFiltersEnabled) { newValue in
                        saveProfile()
                    }

                    Toggle(isOn: $accessibilityEnabled) {
                        Text("Accessibility")
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: lumoGreen))
                    .animation(.easeInOut, value: accessibilityEnabled)
                }
                .padding(.horizontal)

                Spacer()

                // Save confirmation
                if showSaveConfirmation {
                    Text("Profile saved!")
                        .foregroundColor(lumoGreen)
                        .transition(.opacity)
                }

                // Log out Button
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    Text("Log out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lumoGreen, lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .alert("Log Out", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Log Out", role: .destructive) {
                        Task {
                            await logout()
                        }
                    }
                } message: {
                    Text("Are you sure you want to log out?")
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                await loadProfile()
            }
        }
    }

    private func loadProfile() async {
        isLoading = true
        if let user = SupabaseManager.shared.client.auth.currentUser {
            email = user.email ?? ""
        }
        if let profile = await authViewModel.fetchProfile() {
            fullName = profile.full_name
            allergyFiltersEnabled = profile.dietary_filter
        }
        isLoading = false
    }

    private func saveProfile() {
        Task {
            await authViewModel.updateProfile(fullName: fullName, dietaryFilter: allergyFiltersEnabled)
            withAnimation {
                showSaveConfirmation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSaveConfirmation = false
                }
            }
        }
    }
    
    private func logout() async {
        await authViewModel.signOut()
        // The app will automatically navigate back to RootView due to the isLoggedIn state change
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
