// /Views/ContentView.swift

import SwiftUI
import CoreLocation
import MapKit
import MessageUI

struct ContentView: View {
    @State private var locationManager = LocationManager()
    @State private var dataManager = DataManager()
    @State private var photoManager = PhotoManager()
    @State private var tripManager = TripManager()
    @State private var profileManager = ProfileManager()
    @State private var showingSavedLocations = false
    @State private var showingSaveLocationSheet = false
    @State private var showingCamera = false
    @State private var showingMapView = false
    @State private var showingTripsView = false
    @State private var showingStartTripSheet = false
    @State private var showingTripAssignment = false
    @State private var showingProfileView = false
    @State private var locationForTripAssignment: LocationData?
    @State private var pulseAnimation = false
    @State private var showingPhotoSavedAlert = false
    @State private var photoSavedMessage = ""
    
    // Auto-save state
    @State private var autoSaveIndicatorVisible = false
    @State private var lastAutoSaveMessage = ""
    
    // Emergency functionality state
    @State private var showingEmergencySheet = false
    @State private var showingMessageComposer = false
    
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
                                
                                // Profile button
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
                        
                        // Active Trip Banner with Auto-Save Indicator
                        if let activeTrip = tripManager.activeTrip {
                            VStack(spacing: 12) {
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
                                
                                // Auto-Save Status Indicator
                                if activeTrip.autoSaveConfig.isEnabled {
                                    AutoSaveStatusView(
                                        config: activeTrip.autoSaveConfig,
                                        isVisible: autoSaveIndicatorVisible,
                                        lastMessage: lastAutoSaveMessage
                                    )
                                }
                                // Debug info (remove in production)
                                #if DEBUG
                                if activeTrip.autoSaveConfig.isEnabled {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Debug Auto-Save Info:")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                        
                                        Text(tripManager.getAutoSaveDebugInfo())
                                            .font(.caption2)
                                            .foregroundColor(.spotifyTextGray)
                                            .monospaced()
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                    .padding(.horizontal, 24)
                                }
                                #endif
                            }
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
                                showingSaveLocationSheet = true
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
                            
                            // UPDATED: Emergency Button - now checks the toggle setting instead of just hasEmergencyContact
                            if profileManager.shouldShowEmergencyButton() {
                                Button(action: { showingEmergencySheet = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.circle.fill")
                                            .font(.title2)
                                        
                                        Text("Emergency Contact")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 28)
                                            .fill(Color.red)
                                    )
                                }
                                .padding(.horizontal, 24)
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
                                        
                                        let totalPhotos = dataManager.savedLocations.reduce(0) { $0 + $1.photoIdentifiers.count }
                                        let locationsText = "\(dataManager.savedLocations.count) locations"
                                        let photosText = totalPhotos > 0 ? " • \(totalPhotos) photos" : ""
                                        
                                        Text(locationsText + photosText)
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    Spacer()
                                    
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
                setupAutoSaveObserver()
            }
            .onDisappear {
                removeAutoSaveObserver()
            }
            // Monitor location changes for auto-save with street tracking
            .onChange(of: locationManager.currentLocation) { oldLocation, newLocation in
                handleLocationChangeForAutoSave(newLocation)
            }
            // Also monitor address changes for more accurate street detection
            .onChange(of: locationManager.currentAddress) { oldAddress, newAddress in
                handleAddressChangeForAutoSave(newAddress)
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
            // Enhanced StartTripSheet with auto-save configuration
            .sheet(isPresented: $showingStartTripSheet) {
                StartTripSheet { name, description, color, autoSaveConfig in
                    let _ = tripManager.startNewTrip(
                        name: name,
                        description: description,
                        color: color,
                        autoSaveConfig: autoSaveConfig
                    )
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
            .fullScreenCover(isPresented: $showingProfileView) {
                ProfileView(profileManager: profileManager)
            }
            .onChange(of: showingProfileView) { _, newValue in
                print("📞 ContentView: ProfileView sheet state changed to: \(newValue)")
            }
            // Emergency Contact Sheet
            .sheet(isPresented: $showingEmergencySheet) {
                EmergencyContactSheet(
                    profileManager: profileManager,
                    currentLocation: locationManager.currentLocation,
                    currentAddress: locationManager.currentAddress,
                    onDismiss: { showingEmergencySheet = false }
                )
            }
            // Message Composer
            .sheet(isPresented: $showingMessageComposer) {
                MessageComposerView(
                    recipient: profileManager.getEmergencyContactMobile(),
                    recipientName: profileManager.getEmergencyContactName(),
                    currentLocation: locationManager.currentLocation,
                    currentAddress: locationManager.currentAddress,
                    userName: profileManager.getDisplayName()
                )
            }
        }
    }
    
    // MARK: - Enhanced Auto-Save Management with Street Tracking
    private func setupAutoSaveObserver() {
        NotificationCenter.default.addObserver(
            forName: .autoSaveLocationRequested,
            object: nil,
            queue: .main
        ) { [self] notification in
            handleAutoSaveRequest(notification)
        }
    }
    
    private func removeAutoSaveObserver() {
        NotificationCenter.default.removeObserver(self, name: .autoSaveLocationRequested, object: nil)
    }
    
    private func handleAutoSaveRequest(_ notification: Notification) {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        let reason = notification.userInfo?["reason"] as? String ?? "unknown"
        print("🚗 ContentView: Auto-save requested, reason: \(reason)")
        
        // Auto-save the current location
        saveCurrentLocationForAutoSave(reason: reason)
        
        // Show auto-save feedback
        showAutoSaveFeedback(reason: reason)
    }
    
    private func handleLocationChangeForAutoSave(_ newLocation: CLLocation?) {
        guard let newLocation = newLocation else { return }
        
        // Check if we should auto-save based on location change (street-based)
        if tripManager.shouldAutoSaveLocation(newLocation, currentAddress: locationManager.currentAddress) {
            print("🚗 ContentView: Location change triggered auto-save")
            saveCurrentLocationForAutoSave(reason: "roadChange")
            showAutoSaveFeedback(reason: "roadChange")
        }
    }
    
    // Handle address changes for more accurate street detection
    private func handleAddressChangeForAutoSave(_ newAddress: String) {
        guard let currentLocation = locationManager.currentLocation,
              !newAddress.isEmpty,
              newAddress != "Finding your location...",
              newAddress != "Address unavailable" else {
            return
        }
        
        // Check if we should auto-save based on address change (street-based)
        if tripManager.shouldAutoSaveLocation(currentLocation, currentAddress: newAddress) {
            print("🚗 ContentView: Address change triggered auto-save")
            saveCurrentLocationForAutoSave(reason: "roadChange")
            showAutoSaveFeedback(reason: "roadChange")
        }
    }
    
    private func saveCurrentLocationForAutoSave(reason: String) {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        let comment = generateAutoSaveComment(reason: reason)
        saveCurrentLocation(with: comment, isAutoSave: true)
        
        // Pass address to trip manager for street tracking
        tripManager.didAutoSaveLocation(currentLocation, address: locationManager.currentAddress)
    }
    
    private func generateAutoSaveComment(reason: String) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        
        switch reason {
        case "roadChange":
            return "Auto-saved: Street change detected at \(timeString)"
        case "timeInterval":
            return "Auto-saved: Time interval at \(timeString)"
        default:
            return "Auto-saved at \(timeString)"
        }
    }
    
    private func showAutoSaveFeedback(reason: String) {
        let message = reason == "roadChange" ? "Location auto-saved (street change)" : "Location auto-saved (time interval)"
        
        withAnimation(.easeInOut(duration: 0.3)) {
            lastAutoSaveMessage = message
            autoSaveIndicatorVisible = true
        }
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                autoSaveIndicatorVisible = false
            }
        }
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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
    
    private func saveCurrentLocation(with comment: String? = nil, photoIdentifiers: [String] = [], isAutoSave: Bool = false) {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        let locationData = LocationData(
            address: locationManager.currentAddress,
            coordinate: currentLocation.coordinate,
            altitude: currentLocation.altitude,
            comment: comment,
            photoIdentifiers: photoIdentifiers
        )
        
        dataManager.saveLocation(locationData)
        
        // Auto-assign to active trip
        if let activeTrip = tripManager.activeTrip {
            tripManager.addLocationToActiveTrip(locationData.id)
        } else if !tripManager.savedTrips.isEmpty && !isAutoSave {
            // Show trip assignment option if there are existing trips (not for auto-save)
            locationForTripAssignment = locationData
            showingTripAssignment = true
        }
        
        // Haptic feedback (lighter for auto-save)
        let impactFeedback = UIImpactFeedbackGenerator(style: isAutoSave ? .light : .medium)
        impactFeedback.impactOccurred()
    }
    
    // Handle captured image from camera
    private func handleCapturedImage(_ image: UIImage) {
        guard locationManager.currentLocation != nil else { return }
        
        print("Handling captured image...")
        
        photoManager.saveImage(image) { identifier in
            if let identifier = identifier {
                print("Photo saved with identifier: \(identifier)")
                saveLocationWithPhoto(identifier, type: "photo")
            } else {
                print("Failed to save photo")
            }
        }
        
        showingCamera = false
    }
    
    // Handle captured video from camera
    private func handleCapturedVideo(_ url: URL) {
        guard locationManager.currentLocation != nil else { return }
        
        print("Handling captured video...")
        
        photoManager.saveVideo(from: url) { identifier in
            if let identifier = identifier {
                print("Video saved with identifier: \(identifier)")
                saveLocationWithPhoto(identifier, type: "video")
            } else {
                print("Failed to save video")
            }
        }
        
        showingCamera = false
    }
    
    // Save location with photo/video
    private func saveLocationWithPhoto(_ photoIdentifier: String, type: String) {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        print("Saving location with \(type), photo ID: \(photoIdentifier)")
        
        // Check if current location already exists (similar address and within 100m)
        let existingLocation = dataManager.savedLocations.first { savedLocation in
            let distance = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                .distance(from: CLLocation(latitude: savedLocation.coordinate.latitude, longitude: savedLocation.coordinate.longitude))
            
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
            
            photoSavedMessage = "\(type.capitalized) added to existing location: \(existing.address)"
            showingPhotoSavedAlert = true
        } else {
            // Create new location with photo
            print("Creating new location with \(type)")
            saveCurrentLocation(with: "Captured at this location", photoIdentifiers: [photoIdentifier])
            
            photoSavedMessage = "\(type.capitalized) saved! New location created: \(locationManager.currentAddress)"
            showingPhotoSavedAlert = true
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Share Position Functions
    private func shareCurrentPosition() {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        let userName = profileManager.getShareName()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        let timestamp = formatter.string(from: Date())
        
        let coordinate = currentLocation.coordinate
        let encodedAddress = locationManager.currentAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appleMapURL = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedAddress)"
        
        let shareText = """
        \(userName) has shared their current position with you
        
        Date: \(timestamp)
        
        \(locationManager.currentAddress)
        
        📱 Shared from Nice Places app
        """
        
        let activityItems: [Any] = [shareText, URL(string: appleMapURL)!]
        presentActivityController(with: activityItems)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func presentActivityController(with items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTencentWeibo
        ]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Emergency Contact Sheet
struct EmergencyContactSheet: View {
    let profileManager: ProfileManager
    let currentLocation: CLLocation?
    let currentAddress: String
    let onDismiss: () -> Void
    
    @State private var showingMessageComposer = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.red.opacity(0.1), Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "phone.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Emergency Contact")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Contact your emergency person")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Emergency Contact Info
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Emergency Contact")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Text(profileManager.getEmergencyContactName())
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(profileManager.getEmergencyContactMobile())
                                    .font(.subheadline)
                                    .foregroundColor(.spotifyTextGray)
                                    .monospaced()
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        }
                        
                        if let location = currentLocation {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Current Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Text(currentAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Lat: \(String(format: "%.6f", location.coordinate.latitude)), Long: \(String(format: "%.6f", location.coordinate.longitude))")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                    .monospaced()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.spotifyMediumGray.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Call Button
                        Button(action: makePhoneCall) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.title2)
                                
                                Text("Call Emergency Contact")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.red)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // SMS Button
                        Button(action: sendEmergencySMS) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .font(.title2)
                                
                                Text("Send Location via SMS")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.orange)
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Emergency Info
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Text("Emergency Information")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        
                        Text("Use these buttons to quickly contact your emergency contact. Your current location will be shared automatically when sending messages.")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        // FIXED: Add the missing sheet presentation for message composer
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(
                recipient: profileManager.getEmergencyContactMobile(),
                recipientName: profileManager.getEmergencyContactName(),
                currentLocation: currentLocation,
                currentAddress: currentAddress,
                userName: profileManager.getDisplayName()
            )
        }
    }
    
    // MARK: - Emergency Actions
    private func makePhoneCall() {
        let phoneNumber = profileManager.getEmergencyContactMobile()
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if let phoneURL = URL(string: "tel://\(cleanedNumber)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL)
                
                // Strong haptic feedback for emergency action
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
        }
        
        onDismiss()
    }
    
    private func sendEmergencySMS() {
        guard MFMessageComposeViewController.canSendText() else {
            // Fallback to regular SMS app
            sendSMSFallback()
            return
        }
        
        showingMessageComposer = true
    }
    
    private func sendSMSFallback() {
        let phoneNumber = profileManager.getEmergencyContactMobile()
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        var message = "🚨 EMERGENCY: I need help! "
        
        if let location = currentLocation {
            let coordinate = location.coordinate
            let encodedAddress = currentAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let appleMapURL = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedAddress)"
            
            message += "My location: \(currentAddress) - \(appleMapURL)"
        } else {
            message += "I cannot share my exact location right now."
        }
        
        message = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? message
        
        if let smsURL = URL(string: "sms:\(cleanedNumber)&body=\(message)") {
            if UIApplication.shared.canOpenURL(smsURL) {
                UIApplication.shared.open(smsURL)
                
                // Strong haptic feedback for emergency action
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }
        }
        
        onDismiss()
    }
}

// MARK: - Message Composer View
struct MessageComposerView: UIViewControllerRepresentable {
    let recipient: String
    let recipientName: String
    let currentLocation: CLLocation?
    let currentAddress: String
    let userName: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        
        // Set recipient
        composer.recipients = [recipient]
        
        // Create emergency message with location
        var message = "🚨 EMERGENCY: \(userName) needs help!\n\n"
        
        if let location = currentLocation {
            let coordinate = location.coordinate
            let encodedAddress = currentAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let appleMapURL = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedAddress)"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy - HH:mm"
            let timestamp = formatter.string(from: Date())
            
            message += "Time: \(timestamp)\n\n"
            message += "Location: \(currentAddress)\n\n"
            message += "Map: \(appleMapURL)\n\n"
            message += "📱 Sent from Nice Places emergency feature"
        } else {
            message += "I cannot share my exact location right now, but I need assistance.\n\n"
            message += "📱 Sent from Nice Places emergency feature"
        }
        
        composer.body = message
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView
        
        init(_ parent: MessageComposerView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            
            // Provide haptic feedback based on result
            switch result {
            case .sent:
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                print("🚨 Emergency SMS sent successfully")
            case .cancelled:
                print("🚨 Emergency SMS cancelled")
            case .failed:
                print("🚨 Emergency SMS failed to send")
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Auto-Save Status View
struct AutoSaveStatusView: View {
    let config: AutoSaveConfiguration
    let isVisible: Bool
    let lastMessage: String
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "location.fill.viewfinder")
                    .font(.caption)
                    .foregroundColor(.spotifyGreen)
                
                Text(lastMessage)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Auto-save settings indicator
                HStack(spacing: 4) {
                    if config.saveOnRoadChange {
                        Image(systemName: "road.lanes")
                            .font(.caption2)
                            .foregroundColor(.spotifyGreen)
                    }
                    
                    if config.saveOnTimeInterval {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundColor(.spotifyGreen)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.spotifyGreen.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}
