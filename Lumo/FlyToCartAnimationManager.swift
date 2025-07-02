//
//  FlyToCartAnimationManager.swift
//  Lumo
//
//  Created by Ethan on 7/2/25.
//

import SwiftUI

class FlyToCartAnimationManager: ObservableObject {
    struct AnimationRequest: Identifiable {
        let id = UUID()
        let image: Image
        let start: CGPoint
        let end: CGPoint
    }
    
    @Published var currentRequest: AnimationRequest? = nil
    @Published var isAnimating: Bool = false
    @Published var cartPulse: Bool = false
    
    func trigger(image: Image, start: CGPoint, end: CGPoint) {
        print("[FlyToCart] Triggered: start=\(start), end=\(end)")
        currentRequest = AnimationRequest(image: image, start: start, end: end)
        isAnimating = true
    }
    
    func complete() {
        print("[FlyToCart] Animation complete")
        isAnimating = false
        currentRequest = nil
        cartPulse = true
        // Reset pulse after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.cartPulse = false
        }
    }
} 