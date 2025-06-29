//
//  StoreData.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import CoreLocation // Required for CLLocationCoordinate2D
import Foundation // For UUID
import SwiftUI // For Image

// Define your Store struct to include location data
struct Store: Identifiable, Equatable {
    let id = UUID() // Required for Identifiable protocol
    let name: String
    let address: String
    let city: String
    let state: String
    let zip: String
    let phone: String
    let latitude: Double // New
    let longitude: Double // New
}

// Sample store data with example LA coordinates
let sampleLAStores: [Store] = [
    Store(name: "Lumo Downtown LA", address: "123 Main St", city: "Los Angeles", state: "CA", zip: "90012", phone: "(213) 555-1001", latitude: 34.0487, longitude: -118.2518),
    Store(name: "Lumo Santa Monica", address: "456 Ocean Ave", city: "Santa Monica", state: "CA", zip: "90401", phone: "(310) 555-2002", latitude: 34.0195, longitude: -118.4912),
    Store(name: "Lumo Hollywood", address: "789 Sunset Blvd", city: "Hollywood", state: "CA", zip: "90028", phone: "(323) 555-3003", latitude: 34.0901, longitude: -118.3304),
    Store(name: "Lumo Pasadena", address: "101 Colorado Blvd", city: "Pasadena", state: "CA", zip: "91105", phone: "(626) 555-4004", latitude: 34.1478, longitude: -118.1445),
    Store(name: "Lumo Long Beach", address: "200 Pine Ave", city: "Long Beach", state: "CA", zip: "90802", phone: "(562) 555-5005", latitude: 33.7686, longitude: -118.1956)
]

// Extension to make it easier to get CLLocationCoordinate2D from Store
extension Store {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
