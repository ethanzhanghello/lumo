import Foundation
import SwiftUI
import MapKit
import CoreLocation

// LocationManager class that handles location updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are not enabled.")
            return
        }
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()  // Start tracking location
        } else {
            print("Location permission not granted.")
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.first else { return }
        userLocation = newLocation.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            if clError.code == .denied {
                print("Location permission denied.")
            }
        }
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

struct StoreLocationView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var sortedStores: [Store] = []
    @State private var currentStoreIndex: Int = 0
    @EnvironmentObject var appState: AppState

    let allStores: [Store]

    private func sortStoresByDistance() {
        guard let userLocation = locationManager.userLocation else { return }
        sortedStores = allStores
            .map { store in
                (store, distance(from: userLocation, to: store.coordinate))
            }
            .sorted { $0.1 < $1.1 }
            .prefix(5)
            .map { $0.0 }
    }

    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let userLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let storeLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return userLocation.distance(from: storeLocation)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                if let userLocation = locationManager.userLocation {
                    Map(coordinateRegion: .constant(
                        MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    ), showsUserLocation: true)
                    .edgesIgnoringSafeArea(.all)
                } else {
                    ProgressView("Fetching your location...")
                        .foregroundColor(.white)
                }

                if sortedStores.isEmpty {
                    Text("Fetching stores...")
                        .foregroundColor(.white)
                } else {
                    StoreSelectionView(stores: sortedStores)
                }
            }
        }
        .onAppear {
            locationManager.startTracking()
        }
        .onChange(of: locationManager.userLocation) { _ in
            sortStoresByDistance()
        }
    }
}

// Extend CLLocationCoordinate2D to conform to Equatable for onChange functionality
extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// Preview for testing the view with mock location data
struct StoreLocationView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock Location Manager
        let mockLocationManager = LocationManager()
        mockLocationManager.userLocation = CLLocationCoordinate2D(latitude: 37.8715, longitude: -122.2727) // Berkeley location

        return StoreLocationView(allStores: sampleLAStores)
            .environmentObject(AppState())
            .onAppear {
                // Simulate location tracking
                mockLocationManager.startTracking()
            }
    }
} 