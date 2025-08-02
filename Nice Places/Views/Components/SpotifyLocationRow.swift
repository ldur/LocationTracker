// /Views/Components/SpotifyLocationRow.swift

import SwiftUI
import CoreLocation
import Photos

struct SpotifyLocationRow: View {
    let location: LocationData
    let onDelete: () -> Void
    let onTap: () -> Void
    let onMapTap: () -> Void
    let onAddPhotos: () -> Void // NEW: Add photos handler
    let photoManager: PhotoManager
    
    @State private var firstThumbnail: UIImage?
    @State private var isLoadingThumbnail = false
    @State private var profileManager = ProfileManager()
    
    var body: some View {
        HStack(spacing: 16) {
            // Location Icon with Photo Overlay
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.spotifyGreen, Color.spotifyGreen.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    // Show first photo as thumbnail or location icon
                    if let thumbnail = firstThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                // Photo count badge
                                VStack {
                                    HStack {
                                        Spacer()
                                        if location.photoIdentifiers.count > 1 {
                                            Text("\(location.photoIdentifiers.count)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.spotifyGreen)
                                                )
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(4)
                            )
                    } else if isLoadingThumbnail {
                        // Show loading indicator
                        ZStack {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .opacity(0.3)
                            
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.black)
                        }
                    } else {
                        // Show location icon with photo indicator
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                        
                        // Photo indicator overlay
                        if !location.photoIdentifiers.isEmpty {
                            VStack {
                                HStack {
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 18, height: 18)
                                        
                                        if location.photoIdentifiers.count == 1 {
                                            Image(systemName: "camera.fill")
                                                .font(.caption2)
                                                .foregroundColor(.spotifyGreen)
                                        } else {
                                            Text("\(location.photoIdentifiers.count)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.spotifyGreen)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(4)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Location Info (Tappable)
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coordinates")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(formatCoordinates(location.coordinate))
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                                .monospaced()
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Altitude")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(formatAltitude(location.altitude))
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                                .monospaced()
                        }
                    }
                    
                    // Comment section (only show if comment exists)
                    if let comment = location.comment, !comment.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comment")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(comment)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    HStack {
                        Text(location.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray.opacity(0.8))
                        
                        Spacer()
                        
                        // Photo count indicator
                        if !location.photoIdentifiers.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.caption2)
                                Text("\(location.photoIdentifiers.count)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.spotifyGreen)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Action Buttons
            VStack(spacing: 8) {
                // NEW: Add Photos Button
                Button(action: onAddPhotos) {
                    Image(systemName: "photo.badge.plus")
                        .font(.headline)
                        .foregroundColor(.spotifyGreen)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.spotifyMediumGray.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                
                // Share Button
                Button(action: { shareLocation() }) {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.headline)
                        .foregroundColor(.spotifyGreen)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.spotifyMediumGray.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                
                // Map Button
                Button(action: onMapTap) {
                    Image(systemName: "map")
                        .font(.headline)
                        .foregroundColor(.spotifyGreen)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.spotifyMediumGray.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                
                // Details Arrow
                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.spotifyTextGray.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.spotifyMediumGray.opacity(0.6))
        )
        .onAppear {
            loadFirstThumbnail()
        }
        // Enhanced Swipe Actions with Add Photos
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onAddPhotos) {
                Label("Add Photos", systemImage: "photo.badge.plus")
            }
            .tint(.blue)
            
            Button(action: { shareLocation() }) {
                Label("Share", systemImage: "location.fill.viewfinder")
            }
            .tint(.spotifyGreen)
            
            Button(action: onMapTap) {
                Label("Map", systemImage: "map")
            }
            .tint(.blue)
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
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
    
    private func loadFirstThumbnail() {
        guard let firstPhotoId = location.photoIdentifiers.first else {
            return
        }
        
        isLoadingThumbnail = true
        
        Task {
            let thumbnail = await photoManager.loadThumbnail(for: firstPhotoId, size: CGSize(width: 56, height: 56))
            await MainActor.run {
                isLoadingThumbnail = false
                self.firstThumbnail = thumbnail
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
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
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
    SpotifyLocationRow(
        location: LocationData(
            address: "Apple Park, Cupertino, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            altitude: 56.7,
            comment: "Amazing place to visit! The architecture is incredible.",
            photoIdentifiers: ["sample1", "sample2"]
        ),
        onDelete: {},
        onTap: {},
        onMapTap: {},
        onAddPhotos: {}, // NEW: Add photos handler
        photoManager: PhotoManager()
    )
    .preferredColorScheme(.dark)
    .padding()
}
