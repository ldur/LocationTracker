// /Views/Components/MapView.swift

import SwiftUI
import MapKit
import CoreLocation

struct LocationMapView: View {
    let location: CLLocation
    let address: String
    let onDismiss: () -> Void
    
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedDetent: PresentationDetent = .medium
    
    // Initialize camera position with the provided location
    init(location: CLLocation, address: String, onDismiss: @escaping () -> Void) {
        self.location = location
        self.address = address
        self.onDismiss = onDismiss
        
        // Set initial camera position centered on the location
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 2000, // 2km view to show the full 500m radius
                longitudinalMeters: 2000
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(position: $cameraPosition) {
                    // Current location marker
                    Annotation("Your Location", coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.spotifyGreen.opacity(0.3))
                                .frame(width: 30, height: 30)
                            
                            Circle()
                                .fill(Color.spotifyGreen)
                                .frame(width: 16, height: 16)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // 500m radius circle
                    MapCircle(center: location.coordinate, radius: 500) // 500m in meters
                        .foregroundStyle(Color.spotifyGreen.opacity(0.2))
                        .stroke(Color.spotifyGreen, lineWidth: 2)
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                
                // Info Card Overlay
                VStack {
                    Spacer()
                    
                    LocationInfoCard(
                        address: address,
                        coordinate: location.coordinate,
                        altitude: location.altitude
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.spotifyGreen)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: centerOnLocation) {
                            Label("Center on Location", systemImage: "location")
                        }
                        
                        Button(action: openInMaps) {
                            Label("Open in Maps", systemImage: "map")
                        }
                        
                        Button(action: shareLocation) {
                            Label("Share Location", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.spotifyGreen)
                    }
                }
            }
            .toolbarBackground(.thinMaterial, for: .navigationBar)
        }
    }
    
    // MARK: - Helper Functions
    private func centerOnLocation() {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 2000,
                    longitudinalMeters: 2000
                )
            )
        }
    }
    
    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = address
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: location.coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        ])
    }
    
    private func shareLocation() {
        let activityController = UIActivityViewController(
            activityItems: [
                "Check out this location: \(address)",
                URL(string: "http://maps.apple.com/?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)")!
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Location Info Card Component
struct LocationInfoCard: View {
    let address: String
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Location")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(address)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundColor(.spotifyGreen)
            }
            
            // Coordinates and Info
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Latitude")
                        .font(.caption2)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(String(format: "%.6f", coordinate.latitude))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.spotifyTextGray.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                VStack(spacing: 4) {
                    Text("Longitude")
                        .font(.caption2)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(String(format: "%.6f", coordinate.longitude))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.spotifyTextGray.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                VStack(spacing: 4) {
                    Text("Altitude")
                        .font(.caption2)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(altitude.isNaN ? "--- m" : String(format: "%.1f m", altitude))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
            }
            
            // Radius Info
            HStack {
                Image(systemName: "circle.dotted")
                    .font(.caption)
                    .foregroundColor(.spotifyGreen)
                
                Text("Showing 500m radius around your location")
                    .font(.caption)
                    .foregroundColor(.spotifyTextGray)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.spotifyMediumGray.opacity(0.8))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Saved Location Map View
struct SavedLocationMapView: View {
    let location: LocationData
    let onDismiss: () -> Void
    
    @State private var cameraPosition: MapCameraPosition
    
    init(location: LocationData, onDismiss: @escaping () -> Void) {
        self.location = location
        self.onDismiss = onDismiss
        
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    Annotation(location.address, coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.spotifyGreen.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Circle()
                                .fill(Color.spotifyGreen)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 500m radius circle
                    MapCircle(center: location.coordinate, radius: 500)
                        .foregroundStyle(Color.spotifyGreen.opacity(0.2))
                        .stroke(Color.spotifyGreen, lineWidth: 2)
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                
                VStack {
                    Spacer()
                    
                    SavedLocationInfoCard(location: location)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.spotifyGreen)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            let clLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            openLocationInMaps(clLocation, address: location.address)
                        }) {
                            Label("Open in Maps", systemImage: "map")
                        }
                        
                        Button(action: {
                            shareLocationData(location)
                        }) {
                            Label("Share Location", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.spotifyGreen)
                    }
                }
            }
            .toolbarBackground(.thinMaterial, for: .navigationBar)
        }
    }
    
    private func openLocationInMaps(_ location: CLLocation, address: String) {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = address
        mapItem.openInMaps()
    }
    
    private func shareLocationData(_ location: LocationData) {
        var shareText = "Check out this location: \(location.address)"
        if let comment = location.comment {
            shareText += "\n\n\(comment)"
        }
        
        let activityController = UIActivityViewController(
            activityItems: [
                shareText,
                URL(string: "http://maps.apple.com/?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)")!
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Saved Location Info Card
struct SavedLocationInfoCard: View {
    let location: LocationData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Location")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundColor(.spotifyGreen)
            }
            
            if let comment = location.comment, !comment.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Comment")
                        .font(.caption)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(comment)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Saved")
                        .font(.caption2)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(location.timestamp, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                
                if location.photoIdentifiers.count > 0 {
                    Rectangle()
                        .fill(Color.spotifyTextGray.opacity(0.3))
                        .frame(width: 1, height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Photos")
                            .font(.caption2)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text("\(location.photoIdentifiers.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.spotifyMediumGray.opacity(0.8))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - All Locations Map View
struct AllLocationsMapView: View {
    let locations: [LocationData]
    let onDismiss: () -> Void
    let onLocationSelected: (LocationData) -> Void
    
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedLocation: LocationData?
    
    init(locations: [LocationData], onDismiss: @escaping () -> Void, onLocationSelected: @escaping (LocationData) -> Void) {
        self.locations = locations
        self.onDismiss = onDismiss
        self.onLocationSelected = onLocationSelected
        
        // Calculate region to show all locations
        if !locations.isEmpty {
            let coordinates = locations.map { $0.coordinate }
            let minLat = coordinates.map { $0.latitude }.min() ?? 0
            let maxLat = coordinates.map { $0.latitude }.max() ?? 0
            let minLng = coordinates.map { $0.longitude }.min() ?? 0
            let maxLng = coordinates.map { $0.longitude }.max() ?? 0
            
            let centerLat = (minLat + maxLat) / 2
            let centerLng = (minLng + maxLng) / 2
            let spanLat = max((maxLat - minLat) * 1.3, 0.01) // Add 30% padding
            let spanLng = max((maxLng - minLng) * 1.3, 0.01)
            
            self._cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                    span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLng)
                )
            ))
        } else {
            self._cameraPosition = State(initialValue: .automatic)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, selection: $selectedLocation) {
                    ForEach(locations, id: \.id) { location in
                        Annotation(
                            location.address,
                            coordinate: location.coordinate,
                            anchor: .bottom
                        ) {
                            LocationMarkerView(
                                location: location,
                                onTap: {
                                    selectedLocation = location
                                }
                            )
                            .tag(location)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onChange(of: selectedLocation) { _, newLocation in
                    if let location = newLocation {
                        onLocationSelected(location)
                    }
                }
                
                // Info overlay when location is selected
                if let selected = selectedLocation {
                    VStack {
                        Spacer()
                        
                        AllLocationsInfoCard(
                            location: selected,
                            onViewDetails: {
                                onLocationSelected(selected)
                            },
                            onDismiss: {
                                selectedLocation = nil
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.spotifyGreen)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("All Locations")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(locations.count) places")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: fitAllLocationsInView) {
                        Image(systemName: "scope")
                            .font(.title2)
                            .foregroundColor(.spotifyGreen)
                    }
                }
            }
            .toolbarBackground(.thinMaterial, for: .navigationBar)
        }
    }
    
    // Break down complex button action into separate method
    private func fitAllLocationsInView() {
        guard !locations.isEmpty else { return }
        
        let coordinates = locations.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let spanLat = max((maxLat - minLat) * 1.3, 0.01)
        let spanLng = max((maxLng - minLng) * 1.3, 0.01)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                    span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLng)
                )
            )
        }
    }
}

// MARK: - Location Marker Component
struct LocationMarkerView: View {
    let location: LocationData
    let onTap: () -> Void
    
    // Break down complex marker styling
    private var outerGlow: some View {
        Circle()
            .fill(Color.spotifyGreen.opacity(0.3))
            .frame(width: 50, height: 50)
    }
    
    private var mainMarker: some View {
        Circle()
            .fill(Color.spotifyGreen)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
    }
    
    private var photoIndicator: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                    
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
        .frame(width: 50, height: 50)
    }
    
    // Use init with trailing closure for proper Swift syntax
    init(location: LocationData, onTap: @escaping () -> Void) {
        self.location = location
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                outerGlow
                mainMarker
                
                // Location icon
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                
                // Photo indicator overlay
                if !location.photoIdentifiers.isEmpty {
                    photoIndicator
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Locations Info Card
struct AllLocationsInfoCard: View {
    let location: LocationData
    let onViewDetails: () -> Void
    let onDismiss: () -> Void
    
    // Break down complex styling into computed properties
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.thinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.spotifyMediumGray.opacity(0.8))
            )
    }
    
    private var cardOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.spotifyGreen.opacity(0.3), lineWidth: 1)
    }
    
    private var viewDetailsButton: some View {
        Button(action: onViewDetails) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.headline)
                Text("View Details")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.spotifyGreen)
            )
        }
    }
    
    private var photoCountIndicator: some View {
        VStack(spacing: 4) {
            Image(systemName: "photo")
                .font(.headline)
                .foregroundColor(.spotifyGreen)
            
            Text("\(location.photoIdentifiers.count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(width: 60)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("Saved \(location.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.spotifyTextGray)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.spotifyTextGray)
                }
            }
            
            // Comment Section
            if let comment = location.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Action Section
            HStack(spacing: 16) {
                viewDetailsButton
                
                if !location.photoIdentifiers.isEmpty {
                    photoCountIndicator
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .overlay(cardOverlay)
    }
}

#Preview {
    LocationMapView(
        location: CLLocation(latitude: 37.3349, longitude: -122.0090),
        address: "Apple Park, Cupertino, CA 95014",
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
