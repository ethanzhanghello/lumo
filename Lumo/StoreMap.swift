//
//  StoreMap.swift
//  Lumo
//
//  Created by Tony on 6/18/25.
//

import Foundation
import SwiftUI

// MARK: - App Colors Extension for Reusability
extension Color {
    static let lumoGreen = Color(red: 0/255, green: 240/255, blue: 192/255)
    static let darkGrayBackground = Color(red: 49/255, green: 48/255, blue: 49/255)
}

// MARK: - Header Views

struct DualChevronButton: View {
    @Binding var selectedTab: StoreViewTab? // Binding to allow modification of selectedTab

    var body: some View {
        Button(action: {
            selectedTab = nil // Deselect all tabs when chevron is pressed
            print("Dual Chevron button tapped! selectedTab is now: \(selectedTab?.rawValue ?? "None")")
        }) {
            ZStack {
                ChevronShape()
                    .stroke(Color.lumoGreen, lineWidth: 2) // Outer — #00F0C0
                    .offset(x: -3)

                ChevronShape()
                    .stroke(Color.white, lineWidth: 2) // Inner — white
            }
            .frame(width: 30, height: 30)
        }
    }
}

// A custom chevron shape for drawing <<
struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // Build two chevrons <<
        path.move(to: CGPoint(x: w * 0.9, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.9, y: h))

        path.move(to: CGPoint(x: w * 0.6, y: 0))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.6, y: h))

        return path
    }
}

struct AppHeaderView: View {
    @Binding var selectedTab: StoreViewTab? // Pass selectedTab binding to DualChevronButton

    var body: some View {
        HStack {
            // Left: Double chevron
            DualChevronButton(selectedTab: $selectedTab) // Pass the binding here
                .frame(width: 35, height: 35)

            Spacer()

            // Center: App logo — properly centered and scaled
            // Ensure you have "lumo" image in your assets or use a placeholder
            Image("lumo")
                .resizable()
                .scaledToFit()
                .frame(height: 65) // Adjust based on visual alignment

            Spacer()

            // Right: 3D icon
            Button(action: {}) {
                Image(systemName: "cube.transparent")
                    .foregroundColor(Color.lumoGreen)
                    .font(.title2)

            }
        }
        .padding(.horizontal)
        .frame(height: 44) // Height of nav bar
        .background(Color.black)
    }
}

// MARK: - Navigation Tabs View

enum StoreViewTab: String, CaseIterable {
    case browse = "Browse"
    case deals = "Deals"
    case groceryList = "Grocery List"
}

struct NavigationTabsView: View {
    @Binding var selectedTab: StoreViewTab? // Changed to optional

    var body: some View {
        HStack(spacing: 20) { // Reduced spacing for buttons
            ForEach(StoreViewTab.allCases, id: \.self) { tab in
                TabButton(title: tab.rawValue, tab: tab, selectedTab: $selectedTab)
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let tab: StoreViewTab
    @Binding var selectedTab: StoreViewTab? // Changed to optional

    var body: some View {
        Button(action: {
            // If the pressed tab is already selected, deselect it (set to nil)
            // Otherwise, select the new tab
            if selectedTab == tab {
                selectedTab = nil
            } else {
                selectedTab = tab
            }
            print("\(title) tapped, selectedTab is now: \(selectedTab?.rawValue ?? "None")")
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(selectedTab == tab ? .black : .white) // Text color changes for contrast
                .padding(.horizontal, 20) // Horizontal padding for text inside capsule
                .padding(.vertical, 10)     // Vertical padding for text inside capsule
                .background(
                    Capsule() // The circular/rounded button shape
                        .fill(selectedTab == tab ? Color.lumoGreen : Color.black) // Fill changes when selected
                        .stroke(Color.lumoGreen, lineWidth: 2) // Outline is always lumoGreen
                )
        }
    }
}

// MARK: - Store Map Layout and Components

struct StoreMapLayout: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Store perimeter
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.2))
                    )
                FloatingActionButtons()
                    .padding(.top, 5)
                    .padding(.trailing, 15)
                // Main store layout designed to resemble the Target map
                // Adjusted spacing and frame sizes to fit all content within the fixed aspect ratio
                VStack(spacing: geometry.size.height * 0.025) { // Vertical spacing between major rows
                    // Top Row of Departments
                    HStack(spacing: geometry.size.width * 0.02) { // Horizontal spacing within row
                        StoreSection(title: "Seasonal", color: Color.darkGrayBackground)
                        StoreSection(title: "Kitchenware", color: Color.darkGrayBackground)
                        StoreSection(title: "Small Elec.", color: Color.darkGrayBackground)
                        StoreSection(title: "Furniture", color: Color.darkGrayBackground)
                        StoreSection(title: "Bath", color: Color.darkGrayBackground)
                        StoreSection(title: "Bedding", color: Color.darkGrayBackground)
                    }
                    .frame(height: geometry.size.height * 0.08) // Uniform height for this row

                    HStack(spacing: geometry.size.width * 0.02) { // Main horizontal division
                        // Left Block of Departments (Grocery, Health, Pharmacy etc.)
                        VStack(spacing: geometry.size.height * 0.015) {
                            StoreSection(title: "Grocery", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.2)
                            StoreSection(title: "Cleaning Supplies", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.1)
                            StoreSection(title: "Health/Beauty", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.1)
                            StoreSection(title: "Cosmetics", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.08)
                            StoreSection(title: "Pharmacy", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.07)
                        }
                        .frame(width: geometry.size.width * 0.18) // Fixed width for the left block

                        // Central Area: Combines various departmental blocks and open pathways
                        VStack(spacing: geometry.size.height * 0.015) {
                            // First row of central departments
                            HStack(spacing: geometry.size.width * 0.02) {
                                StoreSection(title: "Menswear", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                                StoreSection(title: "Intimate App.", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                                StoreSection(title: "Baby", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                                StoreSection(title: "Infant/Toddler", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                            }

                            // Second row of central departments
                            HStack(spacing: geometry.size.width * 0.02) {
                                StoreSection(title: "Shoes", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.07)
                                StoreSection(title: "Accessories", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.07)
                                StoreSection(title: "Boys", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.07)
                                StoreSection(title: "Girls", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.07)
                            }

                            // Spacer to create an open pathway/middle ground
                            Spacer()

                            // Third row of central departments (more 'aisle-like' blocks)
                            HStack(spacing: geometry.size.width * 0.02) {
                                StoreSection(title: "Electronics", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.08)
                                StoreSection(title: "Home Goods", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.08)
                                StoreSection(title: "Pet Care", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                            }
                            // Fourth row of central departments
                            HStack(spacing: geometry.size.width * 0.02) {
                                StoreSection(title: "Toys", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                                StoreSection(title: "Sporting Goods", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                                StoreSection(title: "Automotive", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.15, height: geometry.size.height * 0.08)
                            }
                            // Fifth row of central departments
                            HStack(spacing: geometry.size.width * 0.02) {
                                StoreSection(title: "Office & School", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.08)
                                StoreSection(title: "Books & Media", color: Color.darkGrayBackground)
                                    .frame(width: geometry.size.width * 0.2, height: geometry.size.height * 0.08)
                            }
                            Spacer() // Another spacer for clear pathway

                            // Checkouts Section
                            StoreSection(title: "Checkouts", color: .gray)
                                .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.05)
                        }
                        .frame(maxWidth: .infinity) // Allows central section to expand

                        // Right Block of Departments (Luggage, Home Storage etc.)
                        VStack(spacing: geometry.size.height * 0.015) {
                            StoreSection(title: "Luggage", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.1)
                            StoreSection(title: "Home Storage", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.1)
                            StoreSection(title: "Home Improvement", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.1)
                            StoreSection(title: "Cards & Party", color: Color.darkGrayBackground)
                                .frame(height: geometry.size.height * 0.08)
                            StoreSection(title: "Sporting Goods", color: Color.darkGrayBackground) // Reusing title, consider unique names if needed
                                .frame(height: geometry.size.height * 0.08)
                        }
                        .frame(width: geometry.size.width * 0.18) // Fixed width for the right block
                    }

                    // Bottom Row of Departments
                    HStack(spacing: geometry.size.width * 0.02) {
                        StoreSection(title: "Cafe", color: .gray)
                        StoreSection(title: "Restrooms", color: .gray)
                        StoreSection(title: "Photo", color: .gray)
                        StoreSection(title: "Guest Service", color: .gray)
                        StoreSection(title: "Portrait Studio", color: .gray)
                    }
                    .frame(height: geometry.size.height * 0.07)
                }
                .padding(geometry.size.width * 0.03) // Overall padding inside the store perimeter

                // Location marker - positioned at a sample location within the new layout
                LocationMarker()
                    .offset(x: geometry.size.width * 0.0, y: geometry.size.height * 0.1) // Adjusted sample position
            }
        }
    }
}

struct StoreSection: View {
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(color.opacity(0.7))
                .frame(maxHeight: .infinity) // Make it fill available height
                .cornerRadius(6)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1) // Prevent text from wrapping too much
                .minimumScaleFactor(0.7) // Allow font to scale down if needed
        }
        .frame(maxWidth: .infinity)
    }
}

struct LocationMarker: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Pulsing circle
            Circle()
                .fill(Color.cyan.opacity(0.3))
                .frame(width: 30, height: 30)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0.0 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // Center dot
            Circle()
                .fill(Color.cyan)
                .frame(width: 12, height: 12)
                .shadow(color: .cyan, radius: 4)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Cart and other action buttons (floating)
struct FloatingActionButtons: View {
    @EnvironmentObject var appState: AppState
    @State private var showingGroceryList = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top button (Cart)
            Button(action: {
                showingGroceryList = true
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Grocery List")
                    Spacer()
                    if appState.groceryList.totalItems > 0 {
                        Text("\(appState.groceryList.totalItems)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                            .background(Color.lumoGreen)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            .sheet(isPresented: $showingGroceryList) {
                GroceryListView()
                    .environmentObject(appState)
            }

            // Divider line
            Rectangle()
                .fill(Color.gray)
                .frame(height: 1)

            // Bottom button (Chevron)
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.cyan) // #00F0C0
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .background(Color.darkGrayBackground)
        }
        .frame(width: 60, height: 100)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(radius: 4)
    }
}

// MARK: - Main Store Map View

struct StoreMapView: View {
    @State private var searchText: String = "" // State for the search text field
    @State private var selectedTab: StoreViewTab? = nil // Changed to optional, initially nil
    @EnvironmentObject var appState: AppState // Add EnvironmentObject for AppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with logo and navigation
                VStack(spacing: 16) {
                    AppHeaderView(selectedTab: $selectedTab) // Pass the binding
                    NavigationTabsView(selectedTab: $selectedTab) // Pass the binding
                }
                .padding(.top, 8)

                // Dynamic Content Section
                ZStack(alignment: .topTrailing) {
                    // Content changes based on selectedTab
                    Group { // Use Group to conditionally display content based on selectedTab
                        if selectedTab == .browse {
                            BrowseView().environmentObject(appState)
                        } else if selectedTab == .deals {
                            // Placeholder for Deals content
                            Text("Awesome Deals Here!")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.purple.opacity(0.3))
                                .cornerRadius(12)
                        } else if selectedTab == .groceryList {
                            GroceryListView().environmentObject(appState)
                        } else {
                            // Default content when no tab is selected (StoreMapLayout)
                            VStack{
                                StoreMapLayout()
                                    .padding(.trailing, 40)
                                // Floating action buttons positioned at the top right of the map section
                                // Search bar - now a TextField with button
                                HStack {
                                    // Magnifying glass as a button
                                    Button(action: {
                                        // Action for search button, e.g., trigger search
                                        print("Search button tapped! Query: \(searchText)")
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 5)

                                    TextField("Search for items...", text: $searchText)
                                        .foregroundColor(.white)
                                        .accentColor(Color.lumoGreen) // Cursor color
                                        .font(.body)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, -30)
                            }
                            
                        }
                    }


                }
                // These paddings apply to the entire content area (map, deals, grocery list)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Complete View and Preview
struct CompleteStoreMapView: View {
    // Add AppState to the environment for the entire app preview
    @StateObject var appState = AppState() // Use @StateObject for the root
    
    var body: some View {
        VStack {
            StoreMapView()
                .environmentObject(appState) // Provide AppState to StoreMapView
        }
    }
}

struct StoreMapView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteStoreMapView()
            .previewDevice("iPhone 16 Pro")
            .preferredColorScheme(.dark)
    }
}
