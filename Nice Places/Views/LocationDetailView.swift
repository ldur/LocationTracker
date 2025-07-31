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
