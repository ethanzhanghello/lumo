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
    @State private var isLoading: Bool = true
    @State private var showSaveConfirmation: Bool = false
    @State private var showingLogoutAlert: Bool = false
    @State private var allergiesSelection: Set<String> = []
    @State private var cuisinesSelection: Set<String> = []
    @State private var restrictionsSelection: Set<String> = []
    let lumoGreen = Color(red: 0/255, green: 240/255, blue: 192/255)
    let allAllergies = ["Peanuts", "Tree Nuts", "Dairy", "Eggs", "Gluten", "Soy", "Fish", "Shellfish"]
    let allCuisines = ["Italian", "Mexican", "Asian", "American", "Indian", "Mediterranean", "French", "Other"]
    let allRestrictions = ["Vegan", "Vegetarian", "Keto", "Paleo", "Halal", "Kosher", "Low-Carb", "None"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Profile Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    // Profile Picture Section
                    VStack {
                        if let url = authViewModel.profilePictureURL, let imageURL = URL(string: url) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(lumoGreen, lineWidth: 2))
                        } else if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(lumoGreen, lineWidth: 2))
                        }
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            Text("Edit Photo")
                                .font(.caption)
                                .foregroundColor(lumoGreen)
                        }
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

                    // Dietary Preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Allergies")
                            .foregroundColor(.white)
                            .font(.headline)
                        WrapChipsView(options: allAllergies, selection: $allergiesSelection, accent: lumoGreen)
                        Text("Preferred Cuisines")
                            .foregroundColor(.white)
                            .font(.headline)
                        WrapChipsView(options: allCuisines, selection: $cuisinesSelection, accent: lumoGreen)
                        Text("Dietary Restrictions")
                            .foregroundColor(.white)
                            .font(.headline)
                        WrapChipsView(options: allRestrictions, selection: $restrictionsSelection, accent: lumoGreen)
                        Button("Save Preferences") {
                            saveProfile()
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(lumoGreen)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Progress Tracking
                    if let stats = authViewModel.userStats {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Trends")
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
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

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
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.ignoresSafeArea())
                .navigationBarHidden(true)
                .task {
                    await loadProfile()
                    await authViewModel.fetchUserStats()
                }
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
        }
    }
    
    private func logout() async {
        await authViewModel.signOut()
    }
}

// Helper view for multi-select chips
struct WrapChipsView: View {
    let options: [String]
    @Binding var selection: Set<String>
    var accent: Color
    var body: some View {
        FlexibleView(data: options, spacing: 8, alignment: .leading) { item in
            Text(item)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selection.contains(item) ? accent : Color.gray.opacity(0.2))
                .foregroundColor(selection.contains(item) ? .black : .white)
                .cornerRadius(16)
                .onTapGesture {
                    if selection.contains(item) {
                        selection.remove(item)
                    } else {
                        selection.insert(item)
                    }
                }
        }
    }
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
