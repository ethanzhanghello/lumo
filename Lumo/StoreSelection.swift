//
//  StoreSelection.swift
//  Lumo
//
//  Created by Tony on 6/16/25.
//

import Foundation
import SwiftUI
import MapKit // Import MapKit for the Map view

struct StoreSelectionView: View {
    let stores: [Store]
    @EnvironmentObject var appState: AppState // Keep AppState
    // Removed @Binding var showStoreSelection: Bool

    // State to manage the currently displayed store's index
    @State private var currentStoreIndex: Int = 0

    // Computed property to get the current store based on the index
    var currentStore: Store {
        if stores.isEmpty {
            return Store(name: "No Store", address: "", city: "", state: "", zip: "", phone: "", latitude: 0, longitude: 0)
        }
        return stores[currentStoreIndex]
    }

    // State for the map's camera position
    @State private var cameraPosition: MapCameraPosition

    // Initializer to set up the initial camera position
    init(stores: [Store]) { // Simplified initializer
        self.stores = stores
        let initialCoordinate = stores.first?.coordinate ?? CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Default to Downtown LA
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Initial zoom
        )))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                // Removed custom Back Button here, NavigationStack handles it.
                HStack {
                    Spacer()
                }
                .padding(.horizontal)

                ZStack{
                    Image("Lumologotest")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.cyan.opacity(0.7), radius: 16)
                        .padding(.bottom, 8)
                }
                .frame(width: 180, height: 100)
                .padding(.bottom, 8)

                Text("Select Your Store")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 8)

                VStack(spacing: 4) {
                    HStack {
                        Image("Lumologotest")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.cyan.opacity(0.5), radius: 5)
                        Text("\(currentStore.name) - \(currentStore.city)")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    .padding(.bottom, 4)

                    Text("\(currentStore.address)\n\(currentStore.city), \(currentStore.state) \(currentStore.zip)\nPhone: \(currentStore.phone)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                Map(position: $cameraPosition) {
                    Annotation(currentStore.name, coordinate: currentStore.coordinate) {
                        Image("Lumologotest")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .shadow(color: .green, radius: 10)
                    }
                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .preferredColorScheme(.dark)
                .frame(height: 180)
                .cornerRadius(16)
                .padding(.horizontal)
                .onChange(of: currentStoreIndex) { oldIndex, newIndex in
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: currentStore.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }

                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            currentStoreIndex = (currentStoreIndex - 1 + stores.count) % stores.count
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.cyan)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(stores.isEmpty)

                        Spacer()

                        Text("Store \(currentStoreIndex + 1) of \(stores.count)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Button(action: {
                            currentStoreIndex = (currentStoreIndex + 1) % stores.count
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.cyan)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(stores.isEmpty)
                    }
                    .padding(.horizontal, 40)

                    Button(action: {
                        print("Selected store: \(currentStore.name)")
                        // This action will trigger the .onReceive in RootView
                        appState.selectedStore = currentStore
                        // No explicit dismiss or navigation here
                    }) {
                        Text("Select This Store")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0/255, green: 240/255, blue: 192/255))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(stores.isEmpty)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct StoreSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreSelectionView(stores: sampleLAStores)
            .environmentObject(AppState())
    }
}
