//  CategoryFilterButton.swift
//  Lumo
//
//  A reusable filter button for category selection (text-only version)

import SwiftUI

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.lumoGreen : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(16)
        }
    }
} 