// /Views/SavedLocations/SpotifySavedLocationsView.swift

import SwiftUI
import CoreLocation
import Photos

struct SpotifySavedLocationsView: View {
    @Bindable var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var photoManager = PhotoManager()
    @State private var locationToEdit: LocationData?
    @State private var selectedLocation: LocationData?
    @State private var locationToViewOnMap: LocationData?
    @State private var showingAllLocationsMap = false
    @State private var locationToAddPhotos: LocationData? // NEW: For adding photos
    @State private var showingMediaLibrary = false // NEW: Media library state
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.spotifyDarkGray,
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.spotifyMediumGray))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("Your Library")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(dataManager.savedLocations.count) saved locations")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                        }
                        
                        Spacer()
                        
                        // View All on Map button
                        if !dataManager.savedLocations.isEmpty {
                            Menu {
                                Button(action: {
                                    showingAllLocationsMap = true
                                }) {
                                    Label("View All on Map", systemImage: "map")
                                }
                                
                                Button(role: .destructive, action: {
                                    dataManager.clearAllLocations()
                                }) {
                                    Label("Clear All", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.spotifyTextGray)
                            }
                        } else {
                            // Placeholder for symmetry
                            Color.clear
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // List Content
                    if dataManager.savedLocations.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "location.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.spotifyTextGray)
                            
                            Text("No Saved Locations")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Start saving your favorite places")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(dataManager.savedLocations.reversed().enumerated()), id: \.element.id) { index, location in
                                    SpotifyLocationRow(
                                        location: location,
                                        onDelete: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                let reversedIndex = dataManager.savedLocations.count - 1 - index
                                                dataManager.deleteLocation(at: IndexSet(integer: reversedIndex))
                                            }
                                        },
                                        onTap: {
                                            selectedLocation = location
                                        },
                                        onMapTap: {
                                            locationToViewOnMap = location
                                        },
                                        onAddPhotos: { // NEW: Handle add photos
                                            locationToAddPhotos = location
                                            showingMediaLibrary = true
                                        },
                                        photoManager: photoManager
                                    )
                                    .contextMenu {
                                        Button(action: {
                                            selectedLocation = location
                                        }) {
                                            Label("View Details", systemImage: "eye")
                                        }
                                        
                                        Button(action: {
                                            locationToAddPhotos = location
                                            showingMediaLibrary = true
                                        }) {
                                            Label("Add Photos", systemImage: "photo.badge.plus")
                                        }
                                        
                                        Button(action: {
                                            locationToViewOnMap = location
                                        }) {
                                            Label("View on Map", systemImage: "map")
                                        }
                                        
                                        Button(action: {
                                            locationToEdit = location
                                        }) {
                                            Label("Edit Location", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                let reversedIndex = dataManager.savedLocations.count - 1 - index
                                                dataManager.deleteLocation(at: IndexSet(integer: reversedIndex))
                                            }
                                        }) {
                                            Label("Delete Location", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .sheet(item: $locationToEdit) { location in
            EditLocationSheet(
                location: location,
                onUpdate: { updatedLocation in
                    dataManager.updateLocation(updatedLocation)
                    locationToEdit = nil
                }
            )
        }
        .fullScreenCover(item: $selectedLocation) { location in
            NavigationStack {
                LocationDetailView(
                    dataManager: dataManager,
                    location: location
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            selectedLocation = nil
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .fullScreenCover(item: $locationToViewOnMap) { location in
            SavedLocationMapView(
                location: location,
                onDismiss: { locationToViewOnMap = nil }
            )
        }
        .fullScreenCover(isPresented: $showingAllLocationsMap) {
            AllLocationsMapView(
                locations: dataManager.savedLocations,
                onDismiss: { showingAllLocationsMap = false },
                onLocationSelected: { location in
                    showingAllLocationsMap = false
                    // Small delay to allow map to dismiss before showing detail
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedLocation = location
                    }
                }
            )
        }
        // NEW: Media Library Sheet
        .sheet(isPresented: $showingMediaLibrary) {
            MediaLibraryAccessSheet(
                maxSelectionCount: 20, // Allow up to 20 items
                locationContext: locationToAddPhotos?.address,
                onMediaSelected: { selectedAssets in
                    handleSelectedMedia(selectedAssets)
                },
                onDismiss: {
                    showingMediaLibrary = false
                    locationToAddPhotos = nil // Clear the location when dismissed
                }
            )
        }
    }
    
    // NEW: Handle selected media from library
    private func handleSelectedMedia(_ selectedAssets: [PHAsset]) {
        guard let targetLocation = locationToAddPhotos else {
            print("❌ No target location for adding photos")
            return
        }
        
        print("📸 SpotifySavedLocationsView: Processing \(selectedAssets.count) selected media items for location: \(targetLocation.address)")
        
        photoManager.processSelectedAssets(selectedAssets) { identifiers in
            print("✅ SpotifySavedLocationsView: Received \(identifiers.count) identifiers")
            DispatchQueue.main.async {
                self.addPhotosToLocation(targetLocation, identifiers: identifiers)
                self.locationToAddPhotos = nil // Clear after processing
            }
        }
    }
    
    // NEW: Add photos to a specific location
    private func addPhotosToLocation(_ location: LocationData, identifiers: [String]) {
        guard !identifiers.isEmpty else { return }
        
        let updatedLocation = LocationData(
            id: location.id,
            address: location.address,
            coordinate: location.coordinate,
            altitude: location.altitude,
            timestamp: location.timestamp,
            comment: location.comment,
            photoIdentifiers: location.photoIdentifiers + identifiers
        )
        
        dataManager.updateLocation(updatedLocation)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✅ Added \(identifiers.count) photos to location: \(location.address)")
    }
}

#Preview {
    SpotifySavedLocationsView(dataManager: DataManager())
        .preferredColorScheme(.dark)
}
