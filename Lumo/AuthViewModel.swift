//
//  AuthViewModel.swift
//  FireBase
//
//  Created by Tony on 7/11/25.
//

import Foundation
import Supabase
import UIKit

struct SupabaseProfile: Codable {
    let id: String
    var full_name: String
    var dietary_filter: Bool
    var profile_picture_url: String?
    var allergies: [String]?
    var preferred_cuisines: [String]?
    var dietary_restrictions: [String]?
}

struct UserStats: Codable {
    let user_id: String
    let meals_planned: Int
    let shopping_lists_created: Int
    let last_updated: String?
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var profilePictureURL: String?
    @Published var allergies: [String] = []
    @Published var preferredCuisines: [String] = []
    @Published var dietaryRestrictions: [String] = []
    @Published var userStats: UserStats?

    func signUp() async {
        errorMessage = nil // Clear previous errors
        
        do {
            try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            // Sign up successful
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        errorMessage = nil // Clear previous errors
        
        do {
            try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            // Sign in successful
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            isAuthenticated = false
            email = ""
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile(fullName: String, dietaryFilter: Bool = false, profilePictureURL: String? = nil, allergies: [String] = [], preferredCuisines: [String] = [], dietaryRestrictions: [String] = []) async {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        let userId = String(describing: user.id)
        let profile = SupabaseProfile(
            id: userId,
            full_name: fullName,
            dietary_filter: dietaryFilter,
            profile_picture_url: profilePictureURL,
            allergies: allergies,
            preferred_cuisines: preferredCuisines,
            dietary_restrictions: dietaryRestrictions
        )
        do {
            _ = try await SupabaseManager.shared.client
                .from("profiles")
                .upsert([profile])
                .execute()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    func fetchProfile() async -> SupabaseProfile? {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return nil }
        let userId = String(describing: user.id)
        do {
            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            let decoder = JSONDecoder()
            let profile = try decoder.decode(SupabaseProfile.self, from: response.data)
            self.profilePictureURL = profile.profile_picture_url
            self.allergies = profile.allergies ?? []
            self.preferredCuisines = profile.preferred_cuisines ?? []
            self.dietaryRestrictions = profile.dietary_restrictions ?? []
            return profile
        } catch {
            print("Failed to fetch profile: \(error)")
            return nil
        }
    }

    func updateProfile(fullName: String, dietaryFilter: Bool, profilePictureURL: String? = nil, allergies: [String] = [], preferredCuisines: [String] = [], dietaryRestrictions: [String] = []) async {
        await saveProfile(fullName: fullName, dietaryFilter: dietaryFilter, profilePictureURL: profilePictureURL, allergies: allergies, preferredCuisines: preferredCuisines, dietaryRestrictions: dietaryRestrictions)
    }

    // Upload profile picture to Supabase Storage and return public URL
    func uploadProfilePicture(image: UIImage) async -> String? {
        print("uploadProfilePicture is not implemented yet.")
        return nil
    }

    // Fetch user stats from user_stats table
    func fetchUserStats() async {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        let userId = String(describing: user.id)
        do {
            let response = try await SupabaseManager.shared.client
                .from("user_stats")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
            let decoder = JSONDecoder()
            let stats = try decoder.decode(UserStats.self, from: response.data)
            self.userStats = stats
        } catch {
            print("Failed to fetch user stats: \(error)")
        }
    }
}
