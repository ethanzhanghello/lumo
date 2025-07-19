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
enum StoreType: String, CaseIterable, Codable, Hashable {
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
struct Store: Identifiable, Equatable, Codable, Hashable {
    let id: UUID // Required for Identifiable protocol
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
    
    init(id: UUID = UUID(), name: String, address: String, city: String, state: String, zip: String, phone: String, latitude: Double, longitude: Double, storeType: StoreType = .grocery, hours: String = "9AM-9PM", rating: Double = 4.5, isFavorite: Bool = false) {
        self.id = id
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
    Store(id: UUID(uuidString: "94D35934-26DF-4109-9634-54CA3DEAB9A0")!, name: "Lumo Downtown LA", address: "123 Main St", city: "Los Angeles", state: "CA", zip: "90012", phone: "(213) 555-1001", latitude: 34.0487, longitude: -118.2518, storeType: .grocery, hours: "7AM-10PM", rating: 4.8, isFavorite: true),
    Store(id: UUID(uuidString: "C8F17F20-9EE1-4938-9B5B-E0E8F6374299")!, name: "Lumo Santa Monica", address: "456 Ocean Ave", city: "Santa Monica", state: "CA", zip: "90401", phone: "(310) 555-2002", latitude: 34.0195, longitude: -118.4912, storeType: .grocery, hours: "8AM-9PM", rating: 4.6),
    Store(id: UUID(uuidString: "95C7EC4E-BCB6-4FDF-9791-52007BF7B4FF")!, name: "Lumo Hollywood", address: "789 Sunset Blvd", city: "Hollywood", state: "CA", zip: "90028", phone: "(323) 555-3003", latitude: 34.0901, longitude: -118.3304, storeType: .department, hours: "9AM-8PM", rating: 4.4),
    Store(id: UUID(uuidString: "A0AE1E98-77FF-45CB-BC4E-8672630B0BC8")!, name: "Lumo Pasadena", address: "101 Colorado Blvd", city: "Pasadena", state: "CA", zip: "91105", phone: "(626) 555-4004", latitude: 34.1478, longitude: -118.1445, storeType: .pharmacy, hours: "8AM-10PM", rating: 4.7),
    Store(id: UUID(uuidString: "953F30A7-532E-4D19-90FD-14046EA77AFA")!, name: "Lumo Long Beach", address: "200 Pine Ave", city: "Long Beach", state: "CA", zip: "90802", phone: "(562) 555-5005", latitude: 33.7686, longitude: -118.1956, storeType: .convenience, hours: "6AM-11PM", rating: 4.2),
    Store(id: UUID(uuidString: "DCF1E5E0-73EA-4BA4-806F-72F209D09E2E")!, name: "Lumo Beverly Hills", address: "300 Rodeo Dr", city: "Beverly Hills", state: "CA", zip: "90210", phone: "(310) 555-6006", latitude: 34.0736, longitude: -118.4004, storeType: .specialty, hours: "10AM-7PM", rating: 4.9, isFavorite: true),
    // --- Berkeley Stores ---
    Store(id: UUID(uuidString: "87782BFC-4087-4E8E-834F-79386FCB064E")!, name: "Berkeley Bowl", address: "2020 Oregon St", city: "Berkeley", state: "CA", zip: "94703", phone: "(510) 843-6929", latitude: 37.8590, longitude: -122.2727, storeType: .grocery, hours: "9AM-8PM", rating: 4.7),
    Store(id: UUID(uuidString: "25491074-90D0-460F-8D0C-293E3A4A435B")!, name: "Trader Joe's Berkeley", address: "1885 University Ave", city: "Berkeley", state: "CA", zip: "94703", phone: "(510) 204-9074", latitude: 37.8715, longitude: -122.2727, storeType: .grocery, hours: "8AM-9PM", rating: 4.6),
    Store(id: UUID(uuidString: "34BF261D-B06B-4507-A25F-D6A4D6E88734")!, name: "Safeway Berkeley", address: "1444 Shattuck Pl", city: "Berkeley", state: "CA", zip: "94709", phone: "(510) 526-3086", latitude: 37.8796, longitude: -122.2697, storeType: .grocery, hours: "6AM-12AM", rating: 4.2),
    Store(id: UUID(uuidString: "b8c9d0e1-f2b3-4567-89ab-cdef01234567")!, name: "Whole Foods Market", address: "3000 Telegraph Ave", city: "Berkeley", state: "CA", zip: "94705", phone: "(510) 649-1333", latitude: 37.8555, longitude: -122.2588, storeType: .grocery, hours: "8AM-10PM", rating: 4.5),
    Store(id: UUID(uuidString: "c9d0e1f2-b3a4-5678-9abc-def012345678")!, name: "Monterey Market", address: "1550 Hopkins St", city: "Berkeley", state: "CA", zip: "94707", phone: "(510) 526-6042", latitude: 37.8822, longitude: -122.2822, storeType: .grocery, hours: "8AM-7PM", rating: 4.8),
    Store(id: UUID(uuidString: "d0e1f2b3-a4b5-6789-abcd-ef0123456789")!, name: "CVS Pharmacy Berkeley", address: "2300 Shattuck Ave", city: "Berkeley", state: "CA", zip: "94704", phone: "(510) 705-8401", latitude: 37.8688, longitude: -122.2670, storeType: .pharmacy, hours: "8AM-10PM", rating: 4.1)
]

// Extension to make it easier to get CLLocationCoordinate2D from Store
extension Store {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
