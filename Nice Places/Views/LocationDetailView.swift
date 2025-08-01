// /Views/LocationDetailView.swift

import SwiftUI
import CoreLocation
import Photos

struct LocationDetailView: View {
    @Bindable var dataManager: DataManager
    @State private var photoManager = PhotoManager()
    
    let location: LocationData
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var showingEditSheet = false
    @State private var showingPhotoViewer = false
    @State private var showingMapView = false // NEW: Map view state
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
                        // Header Section
                        VStack(spacing: 16) {
                            // Location Icon and Address
                            VStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.spotifyGreen, Color.spotifyGreen.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.black)
                                    )
                                
                                Text(location.address)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
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
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Camera Button
                            Button(action: { showingCamera = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    
                                    Text("Add Photos & Videos")
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
                            }
                            .padding(.horizontal, 24)
                            
                            // Share Location Button (NEW)
                            Button(action: {
                                shareLocation()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.fill.viewfinder")
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Share This Location")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Send this saved location to others")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.subheadline)
                                        .opacity(0.7)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.spotifyGreen.opacity(0.8),
                                            Color.spotifyGreen.opacity(0.6)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spotifyGreen, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                            
                            // View on Map Button
                            Button(action: { showingMapView = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "map.fill")
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("View on Map")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("See 500m radius around location")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.subheadline)
                                        .opacity(0.7)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.spotifyMediumGray,
                                            Color.spotifyMediumGray.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                            
                            // Edit Button
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
                        }
                        
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
                                
                                Text("Capture your first memory at this location")
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
            // NEW: Map view for saved location
            SavedLocationMapView(
                location: location,
                onDismiss: { showingMapView = false }
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
    
    // MARK: - Share Location Function (NEW)
    private func shareLocation() {
        // Get device/user name for personalization
        let deviceName = UIDevice.current.name
        let userName = extractUserName(from: deviceName)
        
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
    
    private func extractUserName(from deviceName: String) -> String {
        // Extract user name from device name (e.g., "John's iPhone" -> "John")
        let commonSuffixes = ["'s iPhone", "'s iPad", "'s iPod", " iPhone", " iPad", " iPod"]
        var name = deviceName
        
        for suffix in commonSuffixes {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        
        // If no name found or it's generic, use "Someone"
        if name.isEmpty || name.lowercased().contains("iphone") || name.lowercased().contains("ipad") {
            return "Someone"
        }
        
        return name
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
