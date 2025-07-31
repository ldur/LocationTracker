// /Views/SavedLocations/SpotifySavedLocationsView.swift

import SwiftUI
import CoreLocation

struct SpotifySavedLocationsView: View {
    @Bindable var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var photoManager = PhotoManager()
    @State private var locationToEdit: LocationData?
    @State private var selectedLocation: LocationData?
    
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
                        
                        // Clear all button (only show if there are locations)
                        if !dataManager.savedLocations.isEmpty {
                            Button(action: {
                                dataManager.clearAllLocations()
                            }) {
                                Image(systemName: "trash.circle")
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
                                        photoManager: photoManager
                                    )
                                    .contextMenu {
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
    }
}

#Preview {
    SpotifySavedLocationsView(dataManager: DataManager())
        .preferredColorScheme(.dark)
}
