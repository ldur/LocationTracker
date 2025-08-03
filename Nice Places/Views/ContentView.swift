// /Views/ContentView.swift

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var dataManager = DataManager()
    @State private var photoManager = PhotoManager() // NEW: Photo manager
    @State private var tripManager = TripManager() // NEW: Trip manager
    @State private var profileManager = ProfileManager() // NEW: Profile manager
    @State private var showingSavedLocations = false
    @State private var showingSaveLocationSheet = false // NEW: Sheet state
    @State private var showingCamera = false // NEW: Camera sheet state
    @State private var showingMapView = false // NEW: Map view sheet state
    @State private var showingTripsView = false // NEW: Trips view
    @State private var showingStartTripSheet = false // NEW: Start trip sheet
    @State private var showingTripAssignment = false // NEW: Trip assignment
    @State private var showingProfileView = false // NEW: Profile view
    @State private var locationForTripAssignment: LocationData? // NEW: Location to assign
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
                                
                                // Profile button (NEW)
                                Button(action: {
                                    print("📞 ContentView: Opening ProfileView")
                                    showingProfileView = true
                                }) {
                                    HStack(spacing: 6) {
                                        if profileManager.isProfileSetup() {
                                            // Show user initial if profile is set up
                                            Circle()
                                                .fill(Color.spotifyGreen)
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Text(String(profileManager.userProfile.name.prefix(1)).uppercased())
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.black)
                                                )
                                        } else {
                                            // Show generic profile icon
                                            Image(systemName: "person.circle")
                                                .font(.title2)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                        
                                        if !profileManager.isProfileSetup() {
                                            Text("Profile")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                    }
                                    .padding(.horizontal, profileManager.isProfileSetup() ? 0 : 8)
                                    .padding(.vertical, profileManager.isProfileSetup() ? 0 : 4)
                                    .background(
                                        Capsule()
                                            .fill(profileManager.isProfileSetup() ? Color.clear : Color.spotifyTextGray.opacity(0.2))
                                    )
                                }
                                
                                // Trips button
                                Button(action: { showingTripsView = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "map.circle")
                                            .font(.headline)
                                        Text("Trips")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.spotifyGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.spotifyGreen.opacity(0.2))
                                    )
                                }
                                
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
                        
                        // Active Trip Banner (NEW)
                        if let activeTrip = tripManager.activeTrip {
                            ActiveTripBanner(
                                trip: activeTrip,
                                locationCount: activeTrip.locationIds.count,
                                onTap: {
                                    // Could show trip detail here
                                },
                                onEnd: {
                                    tripManager.endActiveTrip()
                                }
                            )
                        }
                        
                        // Current Location Card with integrated actions
                        SpotifyLocationCard(
                            address: locationManager.currentAddress,
                            coordinate: safeCLLocationCoordinate(locationManager.currentLocation?.coordinate),
                            altitude: safeAltitude(locationManager.currentLocation?.altitude),
                            isUpdating: locationManager.isUpdatingLocation,
                            onViewMap: {
                                showingMapView = true
                            },
                            onSharePosition: {
                                shareCurrentPosition()
                            },
                            onCapturePhoto: {
                                showingCamera = true
                            }
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
            .fullScreenCover(isPresented: $showingMapView) {
                // NEW: Map view for current location
                if let location = locationManager.currentLocation {
                    LocationMapView(
                        location: location,
                        address: locationManager.currentAddress,
                        onDismiss: {
                            showingMapView = false
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
            .sheet(isPresented: $showingTripsView) {
                TripsView(tripManager: tripManager, dataManager: dataManager)
            }
            .sheet(isPresented: $showingStartTripSheet) {
                StartTripSheet { name, description, color in
                    let _ = tripManager.startNewTrip(name: name, description: description, color: color)
                }
            }
            .sheet(isPresented: $showingTripAssignment) {
                if let location = locationForTripAssignment {
                    TripAssignmentSheet(
                        location: location,
                        availableTrips: tripManager.savedTrips.filter { !$0.isActive },
                        onAssignToTrip: { trip in
                            tripManager.addLocationToTrip(location.id, tripId: trip.id)
                        },
                        onCreateNewTrip: {
                            showingStartTripSheet = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showingProfileView) {
                // NEW: Profile view
                ProfileView(profileManager: profileManager)
                    .interactiveDismissDisabled(false) // Allow swipe to dismiss but prevent accidental dismissal
            }
            .onChange(of: showingProfileView) { _, newValue in
                print("📞 ContentView: ProfileView sheet state changed to: \(newValue)")
            }
        }
    }
    
    // MARK: - Safe Value Helpers to Prevent NaN/CoreGraphics Errors
    private func safeCLLocationCoordinate(_ coordinate: CLLocationCoordinate2D?) -> CLLocationCoordinate2D? {
        guard let coordinate = coordinate,
              coordinate.latitude.isFinite && !coordinate.latitude.isNaN,
              coordinate.longitude.isFinite && !coordinate.longitude.isNaN else {
            return nil
        }
        return coordinate
    }
    
    private func safeAltitude(_ altitude: Double?) -> Double? {
        guard let altitude = altitude,
              altitude.isFinite && !altitude.isNaN else {
            return nil
        }
        return altitude
    }
    
    private func saveCurrentLocation(with comment: String? = nil, photoIdentifiers: [String] = []) { // NEW: Added photo identifiers parameter
        guard let currentLocation = locationManager.currentLocation else { return }
        
        let locationData = LocationData(
            address: locationManager.currentAddress,
            coordinate: currentLocation.coordinate,
            altitude: currentLocation.altitude,
            comment: comment, // NEW: Pass comment to LocationData
            photoIdentifiers: photoIdentifiers // NEW: Pass photo identifiers
        )
        
        dataManager.saveLocation(locationData)
        
        // NEW: Auto-assign to active trip
        if let activeTrip = tripManager.activeTrip {
            tripManager.addLocationToActiveTrip(locationData.id)
        } else if !tripManager.savedTrips.isEmpty {
            // Show trip assignment option if there are existing trips
            locationForTripAssignment = locationData
            showingTripAssignment = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // NEW: Handle captured image from camera
    private func handleCapturedImage(_ image: UIImage) {
        guard locationManager.currentLocation != nil else { return }
        
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
        guard locationManager.currentLocation != nil else { return }
        
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
        guard let currentLocation = locationManager.currentLocation else { return }
        
        print("Saving location with \(type), photo ID: \(photoIdentifier)")
        
        // Check if current location already exists (similar address and within 100m)
        let existingLocation = dataManager.savedLocations.first { savedLocation in
            let distance = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
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
    
    // MARK: - Share Position Functions
    
    private func shareCurrentPosition() {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        // Use ProfileManager to get the user name (NEW: Uses profile if available)
        let userName = profileManager.getShareName()
        
        // Create timestamp in DD.MM.YYYY - HH:MM format
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        let timestamp = formatter.string(from: Date())
        
        // Create Apple Maps URL with location name for better display
        let coordinate = currentLocation.coordinate
        let encodedAddress = locationManager.currentAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appleMapURL = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedAddress)"
        
        // Create the share message in new format
        let shareText = """
        \(userName) has shared their current position with you
        
        Date: \(timestamp)
        
        \(locationManager.currentAddress)
        
        📱 Shared from Nice Places app
        """
        
        // Create activity items - separate text and URL for better link handling
        let activityItems: [Any] = [
            shareText,
            URL(string: appleMapURL)!
        ]
        
        // Present activity controller
        presentActivityController(with: activityItems)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func presentActivityController(with items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Customize sharing options
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTencentWeibo
        ]
        
        // Present the activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Find the top-most view controller
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}
