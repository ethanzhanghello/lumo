import SwiftUI

struct EnhancedAisleView: View {
    let aisle: Aisle
    let scale: CGFloat
    let isOnRoute: Bool
    let isCurrent: Bool
    let isNearUser: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(aisleColor)
                .shadow(color: .black.opacity(0.08), radius: isCurrent ? 8 : 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(aisleStrokeColor, lineWidth: strokeWidth)
                )
                .frame(width: 60 * scale, height: 32 * scale)
            HStack(spacing: 4) {
                if let icon = aisleIcon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                Text(aisle.name)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(6)
        }
        .padding(2)
    }
    private var aisleColor: Color {
        if isCurrent {
            return Color.lumoGreen.opacity(0.7)
        } else if isOnRoute {
            return Color.orange.opacity(0.5)
        } else if isNearUser {
            return Color.yellow.opacity(0.3)
        } else {
            return Color.darkGrayBackground.opacity(0.8)
        }
    }
    private var aisleStrokeColor: Color {
        if isCurrent {
            return Color.lumoGreen
        } else if isOnRoute {
            return Color.orange
        } else {
            return Color.white.opacity(0.3)
        }
    }
    private var strokeWidth: CGFloat {
        isCurrent ? 3 : (isOnRoute ? 2 : 1)
    }
    private var aisleIcon: String? {
        // Example: assign icons based on aisle name
        let lower = aisle.name.lowercased()
        if lower.contains("produce") { return "leaf" }
        if lower.contains("dairy") { return "carton" }
        if lower.contains("meat") { return "hare" }
        if lower.contains("bakery") { return "birthday.cake" }
        if lower.contains("frozen") { return "snowflake" }
        if lower.contains("snack") { return "bag" }
        if lower.contains("beverage") { return "cup.and.saucer" }
        return nil
    }
}

struct AisleView: View {
    let aisle: Aisle
    let scale: CGFloat
    let isOnRoute: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(aisleColor)
                .shadow(color: .black.opacity(0.08), radius: isCurrent ? 8 : 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(aisleColor, lineWidth: isCurrent ? 3 : 1)
                )
                .frame(width: 60 * scale, height: 32 * scale)
            Text(aisle.aisleId)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(6)
        }
        .padding(2)
    }
    private var aisleColor: Color {
        if isCurrent {
            return .lumoGreen.opacity(0.7)
        } else if isOnRoute {
            return .orange.opacity(0.5)
        } else {
            return Color.darkGrayBackground.opacity(0.8)
        }
    }
} 