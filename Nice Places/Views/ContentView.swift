// /Views/ContentView.swift

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var dataManager = DataManager()
    @State private var photoManager = PhotoManager() // NEW: Photo manager
    @State private var showingSavedLocations = false
    @State private var showingSaveLocationSheet = false // NEW: Sheet state
    @State private var showingCamera = false // NEW: Camera sheet state
    @State private var pulseAnimation = false
    @State private var showingPhotoSavedAlert = false // NEW: Photo saved feedback
    @State private var photoSavedMessage = "" // NEW: Photo saved message
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Spotify-style gradient background
                LinearGradient(
                    colors: [
                        Color.spotifyDarkGray,
                        Color.spotifyDarkGray.opacity(0.8),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Location")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Tracker")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.spotifyGreen)
                                }
                                
                                Spacer()
                                
                                // Status indicator
                                Circle()
                                    .fill(locationManager.isUpdatingLocation ? Color.spotifyGreen : Color.spotifyTextGray)
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                                    .onAppear {
                                        if locationManager.isUpdatingLocation {
                                            pulseAnimation = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Current Location Card
                        SpotifyLocationCard(
                            address: locationManager.currentAddress,
                            coordinate: locationManager.currentLocation?.coordinate,
                            altitude: locationManager.currentLocation?.altitude,
                            isUpdating: locationManager.isUpdatingLocation
                        )
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Save Location Button
                            Button(action: {
                                showingSaveLocationSheet = true // NEW: Show sheet instead of direct save
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    
                                    Text("Save This Location")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.spotifyGreen)
                                )
                                .scaleEffect(locationManager.currentLocation != nil ? 1.0 : 0.95)
                                .opacity(locationManager.currentLocation != nil ? 1.0 : 0.6)
                                .animation(.easeInOut(duration: 0.2), value: locationManager.currentLocation != nil)
                            }
                            .disabled(locationManager.currentLocation == nil)
                            .padding(.horizontal, 24)
                            
                            // NEW: Camera Button (only show when location is available)
                            if locationManager.currentLocation != nil {
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                        
                                        Text("Capture This Moment")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyMediumGray)
                                    )
                                }
                                .padding(.horizontal, 24)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                            }
                            
                            // View Saved Locations Button
                            Button(action: { showingSavedLocations = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Your Saved Locations")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        
                                        // Show photo count if any locations have photos
                                        let totalPhotos = dataManager.savedLocations.reduce(0) { $0 + $1.photoIdentifiers.count }
                                        let locationsText = "\(dataManager.savedLocations.count) locations"
                                        let photosText = totalPhotos > 0 ? " • \(totalPhotos) photos" : ""
                                        
                                        Text(locationsText + photosText)
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Show camera icon if there are photos
                                    if dataManager.savedLocations.contains(where: { !$0.photoIdentifiers.isEmpty }) {
                                        Image(systemName: "photo.fill")
                                            .font(.caption)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.spotifyMediumGray)
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
            .alert("Permission Required", isPresented: .constant(locationManager.errorMessage != nil)) {
                Button("OK") {
                    locationManager.errorMessage = nil
                }
            } message: {
                Text(locationManager.errorMessage ?? "")
            }
            .sheet(isPresented: $showingSavedLocations) {
                SpotifySavedLocationsView(dataManager: dataManager)
            }
            .sheet(isPresented: $showingSaveLocationSheet) {
                // NEW: Save location sheet with comment input
                if let location = locationManager.currentLocation {
                    SaveLocationSheet(
                        address: locationManager.currentAddress,
                        coordinate: location.coordinate,
                        altitude: location.altitude,
                        onSave: { comment in
                            saveCurrentLocation(with: comment)
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCamera) {
                // NEW: Camera sheet for quick photo capture
                if locationManager.currentLocation != nil {
                    PhotoCaptureSheet(
                        onImageCaptured: { image in
                            handleCapturedImage(image)
                        },
                        onVideoCaptured: { url in
                            handleCapturedVideo(url)
                        },
                        onDismiss: {
                            showingCamera = false
                        }
                    )
                }
            }
            .alert("Photo Saved!", isPresented: $showingPhotoSavedAlert) {
                Button("View Photos") {
                    showingSavedLocations = true
                }
                Button("OK") {}
            } message: {
                Text(photoSavedMessage)
            }
        }
    }
    
    private func saveCurrentLocation(with comment: String? = nil, photoIdentifiers: [String] = []) { // NEW: Added photo identifiers parameter
        guard let location = locationManager.currentLocation else { return }
        
        let locationData = LocationData(
            address: locationManager.currentAddress,
            coordinate: location.coordinate,
            altitude: location.altitude,
            comment: comment, // NEW: Pass comment to LocationData
            photoIdentifiers: photoIdentifiers // NEW: Pass photo identifiers
        )
        
        dataManager.saveLocation(locationData)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // NEW: Handle captured image from camera
    private func handleCapturedImage(_ image: UIImage) {
        guard let location = locationManager.currentLocation else { return }
        
        print("Handling captured image...")
        
        photoManager.saveImage(image) { identifier in
            if let identifier = identifier {
                print("Photo saved with identifier: \(identifier)")
                // Create location with photo or save to existing location
                saveLocationWithPhoto(identifier, type: "photo")
            } else {
                print("Failed to save photo")
            }
        }
        
        showingCamera = false
    }
    
    // NEW: Handle captured video from camera
    private func handleCapturedVideo(_ url: URL) {
        guard let location = locationManager.currentLocation else { return }
        
        print("Handling captured video...")
        
        photoManager.saveVideo(from: url) { identifier in
            if let identifier = identifier {
                print("Video saved with identifier: \(identifier)")
                // Create location with video or save to existing location
                saveLocationWithPhoto(identifier, type: "video")
            } else {
                print("Failed to save video")
            }
        }
        
        showingCamera = false
    }
    
    // NEW: Save location with photo/video
    private func saveLocationWithPhoto(_ photoIdentifier: String, type: String) {
        guard let location = locationManager.currentLocation else { return }
        
        print("Saving location with \(type), photo ID: \(photoIdentifier)")
        
        // Check if current location already exists (similar address and within 100m)
        let existingLocation = dataManager.savedLocations.first { savedLocation in
            let distance = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                .distance(from: CLLocation(latitude: savedLocation.coordinate.latitude, longitude: savedLocation.coordinate.longitude))
            
            // More flexible matching - within 100m OR very similar address
            let isNearby = distance < 100
            let hasSimilarAddress = savedLocation.address.lowercased().contains(locationManager.currentAddress.lowercased().components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "") ||
                                   locationManager.currentAddress.lowercased().contains(savedLocation.address.lowercased().components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "")
            
            return isNearby || hasSimilarAddress
        }
        
        if let existing = existingLocation {
            // Add photo to existing location
            let newPhotoIdentifiers = existing.photoIdentifiers + [photoIdentifier]
            print("Adding \(type) to existing location. New photo count: \(newPhotoIdentifiers.count)")
            
            let updatedLocation = LocationData(
                id: existing.id,
                address: existing.address,
                coordinate: existing.coordinate,
                altitude: existing.altitude,
                timestamp: existing.timestamp,
                comment: existing.comment,
                photoIdentifiers: newPhotoIdentifiers
            )
            dataManager.updateLocation(updatedLocation)
            
            // Show feedback
            photoSavedMessage = "\(type.capitalized) added to existing location: \(existing.address)"
            showingPhotoSavedAlert = true
        } else {
            // Create new location with photo
            print("Creating new location with \(type)")
            saveCurrentLocation(with: "Captured at this location", photoIdentifiers: [photoIdentifier])
            
            // Show feedback
            photoSavedMessage = "\(type.capitalized) saved! New location created: \(locationManager.currentAddress)"
            showingPhotoSavedAlert = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}
