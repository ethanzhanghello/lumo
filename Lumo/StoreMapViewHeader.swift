import SwiftUI

struct RouteProgressHeader: View {
    let route: ShoppingRoute
    let progress: RouteProgress?
    let onShowChecklist: () -> Void
    let onShowSuggestions: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    // TODO: If you want to show completed stops, add logic to RouteProgress and ShoppingRoute
                    Text("Stops: \(route.waypoints.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button("Items", action: onShowChecklist)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    Button("Tips", action: onShowSuggestions)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
            // Progress Bar (if progress is available)
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress.progressPercentage, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                HStack {
                    Text("⏱️ \(progress.estimatedTimeRemaining) min remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("📍 \(Int(progress.remainingDistance))ft to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 