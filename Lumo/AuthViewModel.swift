//
//  AuthViewModel.swift
//  FireBase
//
//  Created by Tony on 7/11/25.
//

import Foundation
import Supabase

struct SupabaseProfile: Codable {
    let id: String
    var full_name: String
    var dietary_filter: Bool
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isAuthenticated = false

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

    func saveProfile(fullName: String, dietaryFilter: Bool = false) async {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        let userId = String(describing: user.id)
        let profile = SupabaseProfile(id: userId, full_name: fullName, dietary_filter: dietaryFilter)
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
            return profile
        } catch {
            print("Failed to fetch profile: \(error)")
            return nil
        }
    }

    func updateProfile(fullName: String, dietaryFilter: Bool) async {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        let userId = String(describing: user.id)
        let profile = SupabaseProfile(id: userId, full_name: fullName, dietary_filter: dietaryFilter)
        do {
            _ = try await SupabaseManager.shared.client
                .from("profiles")
                .upsert([profile])
                .execute()
        } catch {
            print("Failed to update profile: \(error)")
        }
    }
}
