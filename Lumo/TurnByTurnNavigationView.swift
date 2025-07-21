//
//  TurnByTurnNavigationView.swift
//  Lumo
//
//  Turn-by-turn navigation interface for grocery shopping routes
//  Provides step-by-step directions and progress tracking
//

import SwiftUI

struct TurnByTurnNavigationView: View {
    let route: ShoppingRoute
    @StateObject private var routeManager = RouteOptimizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Turn-by-Turn Navigation")
                .font(.title)
                .padding()
            Text("Navigation for route: \(route.id)")
                .foregroundColor(.gray)
            Spacer()
            Button("Close") {
                dismiss()
            }
            .padding()
        }
    }
} 