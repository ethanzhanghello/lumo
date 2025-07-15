import SwiftUI

// Accent color as Color(hex: "#00F0C0")
extension Color {
    static let lumoAccent = Color(red: 0/255, green: 240/255, blue: 192/255)
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let symbol: String
}

struct MovingOrbsBackground: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                Circle()
                    .fill(Color.lumoAccent.opacity(0.25))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(x: animate ? [100, -120, 80, -90][i] : [-80, 120, -100, 90][i],
                            y: animate ? [-120, 100, 90, -80][i] : [100, -90, -120, 80][i])
                    .animation(Animation.easeInOut(duration: 7.0).repeatForever(autoreverses: true).delay(Double(i) * 0.7), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var showOnboarding: Bool
    
    let features: [OnboardingFeature] = [
        OnboardingFeature(
            title: "Personalized Meal Planning",
            description: "Craft your week with smart, AI-powered meal plans tailored to your tastes and goals.",
            symbol: "fork.knife.circle.fill"
        ),
        OnboardingFeature(
            title: "Store Finder & Deals",
            description: "Discover the best stores and hottest deals near you—save money and time every trip!",
            symbol: "mappin.and.ellipse"
        ),
        OnboardingFeature(
            title: "Smart Substitutions",
            description: "Out of an ingredient? Get instant, healthy swaps powered by Lumo’s smart engine.",
            symbol: "wand.and.stars.inverse"
        ),
        OnboardingFeature(
            title: "Grocery List Collaboration",
            description: "Share and manage your grocery list with family or friends—shopping made social!",
            symbol: "person.2.wave.2.fill"
        ),
        OnboardingFeature(
            title: "Nutrition Analysis",
            description: "See the nutrition breakdown of your meals and make healthier choices, effortlessly.",
            symbol: "chart.pie.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MovingOrbsBackground()
            VStack {
                Spacer(minLength: 40)
                ZStack {
                    // Glassmorphism card
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.black.opacity(0.5))
                        .blur(radius: 0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.lumoAccent, lineWidth: 3)
                        )
                        .shadow(color: Color.lumoAccent.opacity(0.18), radius: 18, x: 0, y: 8)
                    VStack(spacing: 28) {
                        Image(systemName: features[currentPage].symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(Color.lumoAccent)
                            .shadow(color: Color.lumoAccent.opacity(0.4), radius: 10, x: 0, y: 6)
                        Text(features[currentPage].title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text(features[currentPage].description)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(36)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .padding(.horizontal, 24)
                Spacer()
                // Custom progress dots
                HStack(spacing: 12) {
                    ForEach(0..<features.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == currentPage ? Color.lumoAccent : Color.white.opacity(0.3))
                            .frame(width: idx == currentPage ? 16 : 8, height: idx == currentPage ? 16 : 8)
                            .shadow(color: idx == currentPage ? Color.lumoAccent.opacity(0.5) : .clear, radius: 6)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                // Navigation buttons
                if currentPage == features.count - 1 {
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        showOnboarding = false
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.lumoAccent
                                    .opacity(0.95)
                                    .shadow(color: Color.lumoAccent.opacity(0.7), radius: 12, x: 0, y: 6)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.lumoAccent, lineWidth: 2)
                            )
                            .padding(.horizontal, 32)
                            .shadow(color: Color.lumoAccent.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    .padding(.bottom, 32)
                } else {
                    Button(action: {
                        withAnimation { currentPage += 1 }
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.lumoAccent
                                    .opacity(0.95)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.lumoAccent, lineWidth: 2)
                            )
                            .padding(.horizontal, 32)
                            .shadow(color: Color.lumoAccent.opacity(0.4), radius: 10, x: 0, y: 6)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(showOnboarding: .constant(true))
    }
} 