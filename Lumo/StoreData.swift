//
//  StoreData.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import CoreLocation // Required for CLLocationCoordinate2D
import Foundation // For UUID
import SwiftUI // For Image

// MARK: - Store Type Enum
enum StoreType: String, CaseIterable, Codable {
    case grocery = "Grocery"
    case pharmacy = "Pharmacy"
    case convenience = "Convenience"
    case department = "Department Store"
    case specialty = "Specialty"
    
    var icon: String {
        switch self {
        case .grocery: return "cart.fill"
        case .pharmacy: return "cross.fill"
        case .convenience: return "building.2.fill"
        case .department: return "building.fill"
        case .specialty: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .grocery: return .green
        case .pharmacy: return .blue
        case .convenience: return .orange
        case .department: return .purple
        case .specialty: return .yellow
        }
    }
}

// Define your Store struct to include location data
struct Store: Identifiable, Equatable, Codable {
    let id = UUID() // Required for Identifiable protocol
    let name: String
    let address: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let latitude: Double
    let longitude: Double
    let storeType: StoreType
    let hours: String
    let rating: Double
    let isFavorite: Bool
    
    init(name: String, address: String, city: String, state: String, zip: String, phone: String, latitude: Double, longitude: Double, storeType: StoreType = .grocery, hours: String = "9AM-9PM", rating: Double = 4.5, isFavorite: Bool = false) {
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zip = zip
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        self.storeType = storeType
        self.hours = hours
        self.rating = rating
        self.isFavorite = isFavorite
    }
}

// Sample store data with example LA coordinates
let sampleLAStores: [Store] = [
    Store(name: "Lumo Downtown LA", address: "123 Main St", city: "Los Angeles", state: "CA", zip: "90012", phone: "(213) 555-1001", latitude: 34.0487, longitude: -118.2518, storeType: .grocery, hours: "7AM-10PM", rating: 4.8, isFavorite: true),
    Store(name: "Lumo Santa Monica", address: "456 Ocean Ave", city: "Santa Monica", state: "CA", zip: "90401", phone: "(310) 555-2002", latitude: 34.0195, longitude: -118.4912, storeType: .grocery, hours: "8AM-9PM", rating: 4.6),
    Store(name: "Lumo Hollywood", address: "789 Sunset Blvd", city: "Hollywood", state: "CA", zip: "90028", phone: "(323) 555-3003", latitude: 34.0901, longitude: -118.3304, storeType: .department, hours: "9AM-8PM", rating: 4.4),
    Store(name: "Lumo Pasadena", address: "101 Colorado Blvd", city: "Pasadena", state: "CA", zip: "91105", phone: "(626) 555-4004", latitude: 34.1478, longitude: -118.1445, storeType: .pharmacy, hours: "8AM-10PM", rating: 4.7),
    Store(name: "Lumo Long Beach", address: "200 Pine Ave", city: "Long Beach", state: "CA", zip: "90802", phone: "(562) 555-5005", latitude: 33.7686, longitude: -118.1956, storeType: .convenience, hours: "6AM-11PM", rating: 4.2),
    Store(name: "Lumo Beverly Hills", address: "300 Rodeo Dr", city: "Beverly Hills", state: "CA", zip: "90210", phone: "(310) 555-6006", latitude: 34.0736, longitude: -118.4004, storeType: .specialty, hours: "10AM-7PM", rating: 4.9, isFavorite: true)
]

// Extension to make it easier to get CLLocationCoordinate2D from Store
extension Store {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
