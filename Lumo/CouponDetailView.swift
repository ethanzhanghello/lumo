//
//  CouponDetailView.swift
//  Lumo
//
//  Created by Ethan on 7/3/25.
//

import SwiftUI

struct CouponDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isClipped = false
    @State private var showingTerms = false
    @State private var showingShareSheet = false
    
    // Mock coupon data
    private let coupon = DigitalCoupon(
        id: "coupon_001",
        title: "$1.00 OFF",
        description: "Any Brand Cereal",
        value: 1.0,
        type: .dollarOff,
        category: "Breakfast",
        brand: "Any Brand",
        minimumPurchase: 0.0,
        maxUses: 1,
        expirationDate: Date().addingTimeInterval(86400 * 7), // 7 days
        applicableStores: sampleLAStores,
        terms: [
            "Valid on any brand cereal product",
            "Cannot be combined with other coupons",
            "One coupon per transaction",
            "Valid in-store only",
            "Expires 7 days from issue date"
        ]
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Coupon Header
                        couponHeaderSection
                        
                        // Coupon Details
                        couponDetailsSection
                        
                        // Terms & Conditions
                        termsSection
                        
                        // Store Information
                        storeSection
                        
                        // Usage Instructions
                        usageInstructionsSection
                        
                        // Similar Coupons
                        similarCouponsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Digital Coupon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingTerms) {
            CouponTermsView(terms: coupon.terms)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["Check out this coupon: \(coupon.title) - \(coupon.description)"])
        }
    }
    
    // MARK: - Coupon Header Section
    private var couponHeaderSection: some View {
        VStack(spacing: 16) {
            // Coupon Visual
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.lumoGreen, Color.lumoGreen.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(coupon.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(coupon.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                    )
                
                // Clip Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isClipped.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: isClipped ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.title2)
                                Text(isClipped ? "Clipped" : "Clip Coupon")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.lumoGreen)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(25)
                            .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            // Expiration Info
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Expires \(coupon.expirationDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(coupon.maxUses) use\(coupon.maxUses == 1 ? "" : "s") remaining")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Coupon Details Section
    private var couponDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coupon Details")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(icon: "tag.fill", title: "Value", value: coupon.title, iconColor: .lumoGreen)
                DetailRow(icon: "cart.fill", title: "Category", value: coupon.category, iconColor: .blue)
                DetailRow(icon: "building.2.fill", title: "Brand", value: coupon.brand, iconColor: .purple)
                
                if coupon.minimumPurchase > 0 {
                    DetailRow(icon: "dollarsign.circle.fill", title: "Minimum Purchase", value: String(format: "$%.2f", coupon.minimumPurchase), iconColor: .orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Terms & Conditions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingTerms = true
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(coupon.terms.prefix(3), id: \.self) { term in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(term)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Store Section
    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available At")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(coupon.applicableStores.prefix(3), id: \.id) { store in
                StoreInfoCard(store: store)
            }
            
            if coupon.applicableStores.count > 3 {
                Button("View All \(coupon.applicableStores.count) Stores") {
                    // Show all stores
                }
                .font(.caption)
                .foregroundColor(.lumoGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Usage Instructions Section
    private var usageInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Use")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InstructionStep(
                    number: 1,
                    title: "Clip the Coupon",
                    description: "Tap the 'Clip Coupon' button above to save this offer to your account"
                )
                
                InstructionStep(
                    number: 2,
                    title: "Shop for Items",
                    description: "Add qualifying items to your cart during your shopping trip"
                )
                
                InstructionStep(
                    number: 3,
                    title: "Checkout",
                    description: "The discount will be automatically applied when you scan your membership card or phone number"
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Similar Coupons Section
    private var similarCouponsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar Coupons")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DealsData.getDigitalCoupons().filter { $0.id != coupon.id }, id: \.id) { similarCoupon in
                        SimilarCouponCard(coupon: similarCoupon)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

// MARK: - Instruction Step Component
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.lumoGreen)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }
            
            Spacer()
        }
    }
}

// MARK: - Similar Coupon Card
struct SimilarCouponCard: View {
    let coupon: DigitalCoupon
    @State private var isClipped = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 80)
                    .overlay(
                        Image(systemName: "ticket.fill")
                            .foregroundColor(.lumoGreen)
                            .font(.title3)
                    )
                
                Button(action: { isClipped.toggle() }) {
                    Image(systemName: isClipped ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(isClipped ? .lumoGreen : .white)
                        .font(.caption)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(coupon.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.lumoGreen)
                
                Text(coupon.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .frame(width: 120)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Coupon Terms View
struct CouponTermsView: View {
    let terms: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Terms & Conditions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(terms, id: \.self) { term in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("•")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    
                                    Text(term)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineSpacing(4)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Digital Coupon Model
struct DigitalCoupon: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let value: Double
    let type: CouponType
    let category: String
    let brand: String
    let minimumPurchase: Double
    let maxUses: Int
    let expirationDate: Date
    let applicableStores: [Store]
    let terms: [String]
    
    static func == (lhs: DigitalCoupon, rhs: DigitalCoupon) -> Bool {
        lhs.id == rhs.id
    }
}

enum CouponType: String, Codable, CaseIterable, Equatable {
    case dollarOff
    case percentageOff
    case bogo
    case freeItem
}

// MARK: - Preview
struct CouponDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CouponDetailView()
    }
} 