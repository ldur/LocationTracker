// /Views/LocationDetailView.swift

import SwiftUI
import CoreLocation
import Photos

struct LocationDetailView: View {
    @Bindable var dataManager: DataManager
    @State private var photoManager = PhotoManager()
    @State private var profileManager = ProfileManager() // NEW: Profile manager
    
    let location: LocationData
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var showingEditSheet = false
    @State private var showingPhotoViewer = false
    @State private var showingMapView = false // NEW: Map view state
    @State private var showingMediaLibrary = false // NEW: Media library state
    @State private var selectedPhotoIndex = 0
    @State private var thumbnails: [String: UIImage] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Spotify background
                LinearGradient(
                    colors: [
                        Color.spotifyDarkGray,
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Section with Integrated Actions
                        VStack(spacing: 16) {
                            // Location Icon, Header Text, and Action Buttons
                            VStack(spacing: 16) {
                                // Main header with icon, text and actions
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.spotifyGreen)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Saved Location")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        Text("Tap to view details")
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Integrated Action Buttons - Single Line
                                    HStack(spacing: 8) {
                                        // Take Photos Button
                                        Button(action: { showingCamera = true }) {
                                            Image(systemName: "camera.fill")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(
                                                    Circle()
                                                        .fill(Color.spotifyGreen.opacity(0.8))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Add from Library Button
                                        Button(action: { showingMediaLibrary = true }) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(
                                                    Circle()
                                                        .fill(Color.spotifyGreen.opacity(0.8))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Share Location Button
                                        Button(action: { shareLocation() }) {
                                            Image(systemName: "location.fill.viewfinder")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(
                                                    Circle()
                                                        .fill(Color.spotifyGreen.opacity(0.8))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // View on Map Button
                                        Button(action: { showingMapView = true }) {
                                            Image(systemName: "map.fill")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(
                                                    Circle()
                                                        .fill(Color.spotifyGreen.opacity(0.8))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                // Address
                                Text(location.address)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 24)
                            
                            // Location Details Card
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Coordinates")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(formatCoordinates(location.coordinate))
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .monospaced()
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 8) {
                                        Text("Altitude")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(formatAltitude(location.altitude))
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .monospaced()
                                    }
                                }
                                
                                if let comment = location.comment, !comment.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Comment")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(comment)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Saved")
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                        Text(location.timestamp, style: .relative)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Photos")
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                        Text("\(location.photoIdentifiers.count)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.spotifyMediumGray)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Edit Location Button (kept as standalone)
                        Button(action: { showingEditSheet = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "pencil")
                                    .font(.title2)
                                
                                Text("Edit Location")
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
                        
                        // Photo Gallery Section
                        if !location.photoIdentifiers.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Photos & Videos")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(location.photoIdentifiers.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyTextGray)
                                }
                                .padding(.horizontal, 24)
                                
                                PhotoGridView(
                                    photoIdentifiers: location.photoIdentifiers,
                                    photoManager: photoManager,
                                    onPhotoTap: { index in
                                        selectedPhotoIndex = index
                                        showingPhotoViewer = true
                                    }
                                )
                            }
                        } else {
                            // Empty State
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.spotifyTextGray.opacity(0.6))
                                
                                Text("No Photos Yet")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Text("Use the camera or library buttons above to add photos")
                                    .font(.subheadline)
                                    .foregroundColor(.spotifyTextGray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            PhotoCaptureSheet(
                onImageCaptured: { image in
                    photoManager.saveImage(image) { identifier in
                        if let identifier = identifier {
                            addPhotoToLocation(identifier)
                        }
                    }
                },
                onVideoCaptured: { url in
                    photoManager.saveVideo(from: url) { identifier in
                        if let identifier = identifier {
                            addPhotoToLocation(identifier)
                        }
                    }
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            EditLocationSheet(
                location: location,
                onUpdate: { updatedLocation in
                    dataManager.updateLocation(updatedLocation)
                }
            )
        }
        .fullScreenCover(isPresented: $showingPhotoViewer) {
            PhotoViewerSheet(
                photoIdentifiers: location.photoIdentifiers,
                initialIndex: selectedPhotoIndex,
                photoManager: photoManager,
                onDismiss: { showingPhotoViewer = false }
            )
        }
        .fullScreenCover(isPresented: $showingMapView) {
            SavedLocationMapView(
                location: location,
                onDismiss: { showingMapView = false }
            )
        }
        // NEW: Media Library Sheet
        .sheet(isPresented: $showingMediaLibrary) {
            MediaLibraryAccessSheet(
                maxSelectionCount: 20, // Allow up to 20 items
                locationContext: location.address,
                onMediaSelected: { selectedAssets in
                    handleSelectedMedia(selectedAssets)
                },
                onDismiss: {
                    showingMediaLibrary = false
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude.isNaN ? "---.----" : String(format: "%.4f", coordinate.latitude)
        let lng = coordinate.longitude.isNaN ? "---.----" : String(format: "%.4f", coordinate.longitude)
        return "\(lat), \(lng)"
    }
    
    private func formatAltitude(_ altitude: Double) -> String {
        return altitude.isNaN ? "--- m" : String(format: "%.1f m", altitude)
    }
    
    private func addPhotoToLocation(_ identifier: String) {
        let updatedLocation = LocationData(
            id: location.id,
            address: location.address,
            coordinate: location.coordinate,
            altitude: location.altitude,
            timestamp: location.timestamp,
            comment: location.comment,
            photoIdentifiers: location.photoIdentifiers + [identifier]
        )
        dataManager.updateLocation(updatedLocation)
    }
    
    // NEW: Handle multiple photos from media library
    private func addPhotosToLocation(_ identifiers: [String]) {
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
    }
    
    // NEW: Handle selected media from library
    private func handleSelectedMedia(_ selectedAssets: [PHAsset]) {
        print("📸 LocationDetailView: Processing \(selectedAssets.count) selected media items")
        
        photoManager.processSelectedAssets(selectedAssets) { identifiers in
            print("✅ LocationDetailView: Received \(identifiers.count) identifiers")
            DispatchQueue.main.async {
                self.addPhotosToLocation(identifiers)
            }
        }
    }
    
    // MARK: - Share Location Function
    private func shareLocation() {
        // Use ProfileManager to get the user name
        let userName = profileManager.getShareName()
        
        // Create timestamp in DD.MM.YYYY - HH:MM format
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        let timestamp = formatter.string(from: Date())
        
        // Create Apple Maps URL with location name for better display
        let coordinate = location.coordinate
        let encodedAddress = location.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appleMapURL = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedAddress)"
        
        // Create the share message in new format
        var shareText = """
        \(userName) has shared a saved location with you
        
        Date: \(timestamp)
        
        \(location.address)
        """
        
        // Add comment if available
        if let comment = location.comment, !comment.isEmpty {
            shareText += "\n\nNote: \(comment)"
        }
        
        // Add saved date
        let savedFormatter = DateFormatter()
        savedFormatter.dateFormat = "dd.MM.yyyy - HH:mm"
        let savedDate = savedFormatter.string(from: location.timestamp)
        shareText += "\n\nOriginally saved: \(savedDate)"
        
        // Add photo count if available
        if !location.photoIdentifiers.isEmpty {
            shareText += "\nPhotos: \(location.photoIdentifiers.count)"
        }
        
        shareText += "\n\n📱 Shared from Nice Places app"
        
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

#Preview {
    LocationDetailView(
        dataManager: DataManager(),
        location: LocationData(
            address: "Apple Park, Cupertino, CA 95014",
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            altitude: 56.7,
            comment: "Amazing architecture and innovative design!",
            photoIdentifiers: ["sample1", "sample2"]
        )
    )
    .preferredColorScheme(.dark)
}
