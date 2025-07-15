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
    @State private var isLoading: Bool = true
    @State private var showSaveConfirmation: Bool = false
    @State private var showingLogoutAlert: Bool = false
    @State private var allergiesSelection: Set<String> = []
    @State private var cuisinesSelection: Set<String> = []
    @State private var restrictionsSelection: Set<String> = []
    @State private var showPasswordSection: Bool = false
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordVisible: Bool = false
    @State private var newPasswordVisible: Bool = false
    @State private var confirmPasswordVisible: Bool = false
    @State private var passwordChangeError: String? = nil
    let lumoGreen = Color(red: 0/255, green: 240/255, blue: 192/255)
    let allAllergies = ["Peanuts", "Tree Nuts", "Dairy", "Eggs", "Gluten", "Soy", "Fish", "Shellfish"]
    let allCuisines = ["Italian", "Mexican", "Asian", "American", "Indian", "Mediterranean", "French", "Other"]
    let allRestrictions = ["Vegan", "Vegetarian", "Keto", "Paleo", "Halal", "Kosher", "Low-Carb", "None"]

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, lumoGreen.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Card
                    VStack(spacing: 20) {
                        ZStack(alignment: .bottomTrailing) {
                            if let url = authViewModel.profilePictureURL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    default:
                                        Image(systemName: "person.crop.circle.fill").resizable()
                                    }
                                }
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .shadow(radius: 8)
                                .overlay(Circle().stroke(lumoGreen, lineWidth: 3))
                            } else if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                    .shadow(radius: 8)
                                    .overlay(Circle().stroke(lumoGreen, lineWidth: 3))
                            }
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                ZStack {
                                    Circle().fill(lumoGreen).frame(width: 36, height: 36)
                                    Image(systemName: "pencil").foregroundColor(.black)
                                }
                                .shadow(radius: 2)
                            }
                            .offset(x: 4, y: 4)
                            .onChange(of: selectedImage) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                        profileImage = Image(uiImage: uiImage)
                                        if let url = await authViewModel.uploadProfilePicture(image: uiImage) {
                                            await authViewModel.updateProfile(
                                                fullName: fullName,
                                                dietaryFilter: false,
                                                profilePictureURL: url,
                                                allergies: Array(allergiesSelection),
                                                preferredCuisines: Array(cuisinesSelection),
                                                dietaryRestrictions: Array(restrictionsSelection)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        Text("@\(email.split(separator: "@").first ?? "user")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        // Editable Full Name
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Full Name", systemImage: "person.fill")
                                .foregroundColor(lumoGreen)
                                .font(.headline)
                            TextField("Enter your name", text: $fullName)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .accentColor(lumoGreen)
                        }
                        // Email (read-only)
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Email", systemImage: "envelope.fill")
                                .foregroundColor(lumoGreen)
                                .font(.headline)
                            TextField("", text: .constant(email))
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .accentColor(lumoGreen)
                                .disabled(true)
                        }
                        // Change Password Section
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Password", systemImage: "lock.fill")
                                .foregroundColor(lumoGreen)
                                .font(.headline)
                            Button(action: { withAnimation { showPasswordSection.toggle() } }) {
                                HStack {
                                    Text(showPasswordSection ? "Cancel Password Change" : "Change Password")
                                    Spacer()
                                    Image(systemName: showPasswordSection ? "chevron.up" : "chevron.down")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                            }
                            if showPasswordSection {
                                VStack(spacing: 10) {
                                    SecureInputField(title: "Current Password", text: $currentPassword, isVisible: $passwordVisible, accent: lumoGreen)
                                    SecureInputField(title: "New Password", text: $newPassword, isVisible: $newPasswordVisible, accent: lumoGreen)
                                    SecureInputField(title: "Confirm New Password", text: $confirmPassword, isVisible: $confirmPasswordVisible, accent: lumoGreen)
                                    if let error = passwordChangeError {
                                        Text(error).foregroundColor(.red).font(.caption)
                                    }
                                    Button(action: {
                                        Task { await changePassword() }
                                    }) {
                                        Text("Update Password")
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 8)
                                            .background(lumoGreen)
                                            .cornerRadius(10)
                                    }
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(28)
                    .shadow(radius: 12)
                    .padding(.horizontal)

                    // Preferences Section
                    VStack(alignment: .leading, spacing: 20) {
                        Label("Allergies", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(lumoGreen)
                            .font(.headline)
                        AnimatedChipsView(options: allAllergies, selection: $allergiesSelection, accent: lumoGreen)
                        Label("Preferred Cuisines", systemImage: "fork.knife")
                            .foregroundColor(lumoGreen)
                            .font(.headline)
                        AnimatedChipsView(options: allCuisines, selection: $cuisinesSelection, accent: lumoGreen)
                        Label("Dietary Restrictions", systemImage: "leaf.fill")
                            .foregroundColor(lumoGreen)
                            .font(.headline)
                        AnimatedChipsView(options: allRestrictions, selection: $restrictionsSelection, accent: lumoGreen)
                        Button("Save Preferences") {
                            saveProfile()
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(lumoGreen)
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(BlurView(style: .systemUltraThinMaterialDark))
                    .cornerRadius(28)
                    .shadow(radius: 12)
                    .padding(.horizontal)

                    // Progress Tracking
                    if let stats = authViewModel.userStats {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Your Trends", systemImage: "chart.bar.fill")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(lumoGreen)
                            HStack {
                                VStack {
                                    Text("Meals Planned")
                                        .foregroundColor(.white)
                                    Text("\(stats.meals_planned)")
                                        .font(.title)
                                        .foregroundColor(lumoGreen)
                                }
                                Spacer()
                                VStack {
                                    Text("Shopping Lists")
                                        .foregroundColor(.white)
                                    Text("\(stats.shopping_lists_created)")
                                        .font(.title)
                                        .foregroundColor(lumoGreen)
                                }
                            }
                        }
                        .padding()
                        .background(BlurView(style: .systemUltraThinMaterialDark))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Save confirmation
                    if showSaveConfirmation {
                        Text("Profile saved!")
                            .foregroundColor(lumoGreen)
                            .font(.headline)
                            .padding(.top, 8)
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
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .navigationBarHidden(true)
                .task {
                    await loadProfile()
                    await authViewModel.fetchUserStats()
                }
            }
            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: lumoGreen))
                    .scaleEffect(1.5)
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
            allergiesSelection = Set(profile.allergies ?? [])
            cuisinesSelection = Set(profile.preferred_cuisines ?? [])
            restrictionsSelection = Set(profile.dietary_restrictions ?? [])
        }
        isLoading = false
    }

    private func saveProfile() {
        isLoading = true
        Task {
            await authViewModel.updateProfile(
                fullName: fullName,
                dietaryFilter: false,
                profilePictureURL: authViewModel.profilePictureURL,
                allergies: Array(allergiesSelection),
                preferredCuisines: Array(cuisinesSelection),
                dietaryRestrictions: Array(restrictionsSelection)
            )
            withAnimation {
                showSaveConfirmation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSaveConfirmation = false
                }
            }
            isLoading = false
        }
    }
    
    private func changePassword() async {
        guard newPassword == confirmPassword else {
            withAnimation { passwordChangeError = "Passwords do not match." }
            return
        }
        isLoading = true
        let success = await authViewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        isLoading = false
        if success {
            withAnimation {
                showPasswordSection = false
                passwordChangeError = nil
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            }
        } else {
            withAnimation {
                passwordChangeError = authViewModel.errorMessage ?? "Failed to change password."
            }
        }
    }
    
    private func logout() async {
        await authViewModel.signOut()
    }
}

// SecureInputField: Custom field with eye toggle
struct SecureInputField: View {
    let title: String
    @Binding var text: String
    @Binding var isVisible: Bool
    var accent: Color
    var body: some View {
        HStack {
            if isVisible {
                TextField(title, text: $text)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .accentColor(accent)
            } else {
                SecureField(title, text: $text)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .accentColor(accent)
            }
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(accent)
            }
            .padding(.trailing, 8)
        }
    }
}

// AnimatedChipsView: Chips with checkmark and animation
struct AnimatedChipsView: View {
    let options: [String]
    @Binding var selection: Set<String>
    var accent: Color
    var body: some View {
        FlexibleView(data: options, spacing: 8, alignment: .leading) { item in
            HStack(spacing: 6) {
                Text(item)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selection.contains(item) ? accent : Color.gray.opacity(0.2))
                    .foregroundColor(selection.contains(item) ? .black : .white)
                    .cornerRadius(16)
                    .overlay(
                        Group {
                            if selection.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.black)
                                    .offset(x: 12, y: -12)
                                    .transition(.scale)
                            }
                        }, alignment: .topTrailing
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if selection.contains(item) {
                                selection.remove(item)
                            } else {
                                selection.insert(item)
                            }
                        }
                    }
            }
        }
    }
}

// BlurView for glass effect
import UIKit
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// FlexibleView for wrapping chips
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var totalHeight = CGFloat.zero
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    private func generateContent(in g: GeometryProxy) -> some View {
        let items = Array(data)
        let last = items.last
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(items, id: \ .self) { item in
                content(item)
                    .padding([.vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if item == last {
                            width = 0 // Last item
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == last {
                            height = 0 // Last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
        }
        .onPreferenceChange(ViewHeightKey.self) { value in
            binding.wrappedValue = value
        }
    }
}
private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
