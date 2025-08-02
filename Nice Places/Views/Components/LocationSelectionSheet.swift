// /Views/Components/LocationSelectionSheet.swift

import SwiftUI
import Photos

struct LocationSelectionSheet: View {
    let selectedAssets: [PHAsset]
    let locations: [LocationData]
    let onLocationSelected: (LocationData, [PHAsset]) -> Void
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var selectedLocation: LocationData?
    
    private var filteredLocations: [LocationData] {
        if searchText.isEmpty {
            return locations.sorted { $0.timestamp > $1.timestamp }
        } else {
            return locations.filter { location in
                location.address.localizedCaseInsensitiveContains(searchText) ||
                (location.comment?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add to Location")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Choose where to add \(selectedAssets.count) item\(selectedAssets.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.spotifyTextGray)
                            }
                            
                            Spacer()
                            
                            Button("Cancel") {
                                onDismiss()
                            }
                            .foregroundColor(.spotifyTextGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Selected Media Preview
                        if !selectedAssets.isEmpty {
                            MediaPreviewRow(assets: Array(selectedAssets.prefix(5)))
                                .padding(.horizontal, 24)
                        }
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.spotifyTextGray)
                            
                            TextField("Search locations...", text: $searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.spotifyMediumGray.opacity(0.6))
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)
                    
                    // Locations List
                    if filteredLocations.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: searchText.isEmpty ? "location.slash" : "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(searchText.isEmpty ? "No Saved Locations" : "No Matching Locations")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(searchText.isEmpty ? "Save some locations first to add media" : "Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredLocations, id: \.id) { location in
                                    LocationSelectionRow(
                                        location: location,
                                        isSelected: selectedLocation?.id == location.id,
                                        onSelect: {
                                            selectedLocation = location
                                            // Add small delay for visual feedback
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                onLocationSelected(location, selectedAssets)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Media Preview Row
struct MediaPreviewRow: View {
    let assets: [PHAsset]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(assets.enumerated()), id: \.offset) { index, asset in
                MediaPreviewThumbnail(asset: asset)
            }
            
            if assets.count < 5 && assets.count > 0 {
                // Show count if more items
                let totalCount = assets.count
                if totalCount > 5 {
                    HStack(spacing: 4) {
                        Text("+\(totalCount - 5)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("more")
                            .font(.caption2)
                            .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.spotifyMediumGray.opacity(0.8))
                    )
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Media Preview Thumbnail
struct MediaPreviewThumbnail: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.spotifyMediumGray)
                .frame(width: 50, height: 50)
            
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.spotifyGreen)
            }
            
            // Video indicator
            if asset.mediaType == .video {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .background(Circle().fill(.black.opacity(0.6)))
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 50, height: 50),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - Location Selection Row
struct LocationSelectionRow: View {
    let location: LocationData
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Location Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected ?
                            LinearGradient(colors: [Color.spotifyGreen, Color.spotifyGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.spotifyMediumGray, Color.spotifyMediumGray.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "location.fill")
                        .font(.headline)
                        .foregroundColor(isSelected ? .black : .spotifyTextGray)
                }
                
                // Location Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(location.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        if !location.photoIdentifiers.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.caption2)
                                Text("\(location.photoIdentifiers.count)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.spotifyGreen)
                        }
                        
                        if let comment = location.comment, !comment.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text("Has note")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.spotifyGreen : Color.spotifyTextGray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.spotifyGreen)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.spotifyGreen.opacity(0.1) : Color.spotifyMediumGray.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.spotifyGreen.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LocationSelectionSheet(
        selectedAssets: [],
        locations: [
            LocationData(
                address: "Apple Park, Cupertino, CA",
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                altitude: 56.7,
                comment: "Amazing place!",
                photoIdentifiers: ["photo1", "photo2"]
            )
        ],
        onLocationSelected: { _, _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
