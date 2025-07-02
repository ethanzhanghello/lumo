//
//  FlyToCartOverlay.swift
//  Lumo
//
//  Created by Ethan on 7/2/25.
//

import SwiftUI

struct FlyToCartOverlay: View {
    @EnvironmentObject var manager: FlyToCartAnimationManager
    @State private var animProgress: CGFloat = 0
    @State private var animating = false
    
    var body: some View {
        GeometryReader { geo in
            if let req = manager.currentRequest, manager.isAnimating {
                req.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .border(Color.red, width: 2) // DEBUG: red border
                    .position(x: lerp(req.start.x, req.end.x, animProgress),
                              y: bezierY(t: animProgress, start: req.start, end: req.end))
                    .scaleEffect(1 - 0.3 * animProgress)
                    .opacity(Double(1 - animProgress))
                    .onAppear {
                        print("[FlyToCartOverlay] onAppear: start=\(req.start), end=\(req.end)")
                        animProgress = 0
                        animating = true
                        withAnimation(.easeInOut(duration: 0.45)) {
                            animProgress = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            animating = false
                            manager.complete()
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }
    
    // Linear interpolation
    func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
    // Simple quadratic bezier for arc
    func bezierY(t: CGFloat, start: CGPoint, end: CGPoint) -> CGFloat {
        let controlY = min(start.y, end.y) - 80 // arc height
        let oneMinusT = 1 - t
        return oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * controlY + t * t * end.y
    }
} 