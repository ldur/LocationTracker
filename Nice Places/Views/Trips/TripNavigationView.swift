// /Views/Trips/TripNavigationView.swift

import SwiftUI
import MapKit
import CoreLocation

struct TripNavigationView: View {
    let trip: Trip
    let locations: [LocationData]
    let startLocationIndex: Int
    let onDismiss: () -> Void
    
    @State private var navigationManager = NavigationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingExitConfirmation = false
    @State private var showingRouteOverview = false
    @State private var isFollowingUser = true
    @State private var mapRotation: Double = 0
    
    // UI State
    @State private var showFullInstructions = false
    @State private var selectedDetent: PresentationDetent = .fraction(0.3)
    
    private var sortedLocations: [LocationData] {
        locations.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        ZStack {
            // Navigation Map
            NavigationMapView(
                navigationManager: navigationManager,
                cameraPosition: $cameraPosition,
                isFollowingUser: $isFollowingUser,
                mapRotation: $mapRotation,
                trip: trip,
                locations: sortedLocations
            )
            .ignoresSafeArea()
            
            // Top Navigation Bar
            VStack {
                NavigationTopBar(
                    navigationManager: navigationManager,
                    onExit: { showingExitConfirmation = true },
                    onToggleOverview: { showingRouteOverview.toggle() },
                    onRecenter: {
                        isFollowingUser = true
                        updateCameraToUserLocation()
                    }
                )
                
                Spacer()
            }
            
            // Bottom Navigation Panel
            VStack {
                Spacer()
                
                NavigationInstructionPanel(
                    navigationManager: navigationManager,
                    trip: trip,
                    showFullInstructions: $showFullInstructions,
                    onSkipLocation: {
                        Task {
                            await navigationManager.skipToNextLocation()
                        }
                    }
                )
            }
        }
        .onAppear {
            Task {
                await startNavigation()
            }
        }
        .onDisappear {
            navigationManager.stopNavigation()
        }
        .onChange(of: navigationManager.userLocation) { _, newLocation in
            if isFollowingUser, let location = newLocation {
                updateCameraToLocation(location)
            }
        }
        .alert("Exit Navigation", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) {
                navigationManager.stopNavigation()
                onDismiss()
            }
        } message: {
            Text("Are you sure you want to exit navigation?")
        }
        .sheet(isPresented: $showingRouteOverview) {
            NavigationRouteOverview(
                navigationManager: navigationManager,
                trip: trip,
                locations: sortedLocations
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private func startNavigation() async {
        await navigationManager.startNavigation(for: trip, locations: sortedLocations, startIndex: startLocationIndex)
    }
    
    private func updateCameraToUserLocation() {
        guard let location = navigationManager.userLocation else { return }
        updateCameraToLocation(location)
    }
    
    private func updateCameraToLocation(_ location: CLLocation) {
        withAnimation(.easeInOut(duration: 0.5)) {
            let heading = navigationManager.userHeading?.trueHeading ?? 0
            
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 500, // Zoom level for navigation
                    heading: isFollowingUser ? heading : 0,
                    pitch: 60 // Tilted view for navigation
                )
            )
            
            if isFollowingUser {
                mapRotation = heading
            }
        }
    }
}

// MARK: - Navigation Map View
struct NavigationMapView: View {
    var navigationManager: NavigationManager
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isFollowingUser: Bool
    @Binding var mapRotation: Double
    let trip: Trip
    let locations: [LocationData]
    
    var body: some View {
        Map(position: $cameraPosition) {
            // User Location
            if let userLocation = navigationManager.userLocation {
                Annotation("", coordinate: userLocation.coordinate) {
                    NavigationUserMarker(heading: navigationManager.userHeading?.trueHeading)
                }
            }
            
            // Current Route
            if let route = navigationManager.currentRoute {
                MapPolyline(route.polyline)
                    .stroke(trip.color.color, style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round,
                        lineJoin: .round
                    ))
                
                // Alternative style for better visibility
                MapPolyline(route.polyline)
                    .stroke(.white.opacity(0.5), style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round,
                        lineJoin: .round
                    ))
            }
            
            // Destination Markers
            ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                let isCompleted = index < navigationManager.currentLocationIndex
                let isCurrent = index == navigationManager.currentLocationIndex
                let isFuture = index > navigationManager.currentLocationIndex
                
                Annotation(
                    location.address,
                    coordinate: location.coordinate,
                    anchor: .bottom
                ) {
                    NavigationLocationMarker(
                        location: location,
                        index: index + 1,
                        tripColor: trip.color.color,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isFuture: isFuture
                    )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
                .mapControlVisibility(.visible)
        }
        .onTapGesture {
            // Disable follow mode when user interacts with map
            isFollowingUser = false
        }
    }
}

// MARK: - Navigation User Marker
struct NavigationUserMarker: View {
    let heading: Double?
    
    var body: some View {
        ZStack {
            // Direction cone
            if let heading = heading {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(heading))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            // Pulsing animation
            Circle()
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                .frame(width: 40, height: 40)
                .scaleEffect(1.5)
                .opacity(0)
                .animation(
                    Animation.easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: UUID()
                )
        }
    }
}

// MARK: - Navigation Location Marker
struct NavigationLocationMarker: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let isCompleted: Bool
    let isCurrent: Bool
    let isFuture: Bool
    
    var body: some View {
        ZStack {
            if isCurrent {
                // Pulsing current destination
                Circle()
                    .fill(tripColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.2)
                    .opacity(0.5)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
            
            // Main marker
            Circle()
                .fill(isCompleted ? Color.gray : (isCurrent ? tripColor : tripColor.opacity(0.7)))
                .frame(width: isCurrent ? 40 : 32, height: isCurrent ? 40 : 32)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
                .shadow(color: .black.opacity(0.3), radius: 3)
            
            // Direction indicator for current destination
            if isCurrent {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 12))
                    .foregroundColor(tripColor)
                    .offset(y: 25)
            }
        }
    }
}

// MARK: - Navigation Top Bar
struct NavigationTopBar: View {
    var navigationManager: NavigationManager
    let onExit: () -> Void
    let onToggleOverview: () -> Void
    let onRecenter: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Exit Button
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    )
            }
            
            // Status Bar
            HStack {
                if navigationManager.isCalculatingRoute || navigationManager.isRerouting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else if !navigationManager.isOnRoute {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let destination = navigationManager.getCurrentDestination() {
                        Text("Navigating to")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(destination.address.components(separatedBy: ",").first ?? destination.address)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // ETA
                if let eta = navigationManager.etaToNextLocation {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ETA")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(eta, style: .time)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.spotifyMediumGray.opacity(0.9))
                    )
            )
            
            // Menu Button
            Menu {
                Button(action: onToggleOverview) {
                    Label("Route Overview", systemImage: "map")
                }
                
                Button(action: onRecenter) {
                    Label("Recenter Map", systemImage: "location")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }
}

// MARK: - Navigation Instruction Panel
struct NavigationInstructionPanel: View {
    var navigationManager: NavigationManager
    let trip: Trip
    @Binding var showFullInstructions: Bool
    let onSkipLocation: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Direction Card
            VStack(spacing: 16) {
                // Current Instruction
                HStack(spacing: 16) {
                    // Turn Icon
                    NavigationTurnIcon(instruction: navigationManager.currentInstruction)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(trip.color.color)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(navigationManager.currentInstruction.isEmpty ? "Calculating route..." : navigationManager.currentInstruction)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            // Distance to turn
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.caption)
                                Text(navigationManager.formatDistance(navigationManager.distanceToNextTurn))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.spotifyGreen)
                            
                            // Time remaining
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(navigationManager.formatTime(navigationManager.timeToDestination))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.spotifyTextGray)
                            
                            // Distance remaining
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.caption)
                                Text(navigationManager.formatDistance(navigationManager.distanceToNextLocation))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.spotifyTextGray)
                        }
                    }
                    
                    Spacer()
                }
                
                // Next Instruction Preview
                if !navigationManager.nextInstruction.isEmpty {
                    HStack(spacing: 12) {
                        Text("Then:")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text(navigationManager.nextInstruction)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.leading, 76)
                }
                
                Divider()
                    .background(Color.spotifyTextGray.opacity(0.3))
                
                // Navigation Controls
                HStack(spacing: 16) {
                    // Skip to Next Location
                    if navigationManager.currentLocationIndex < navigationManager.tripLocations.count - 1 {
                        Button(action: onSkipLocation) {
                            HStack(spacing: 8) {
                                Image(systemName: "forward.fill")
                                    .font(.caption)
                                Text("Skip Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.spotifyTextGray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.spotifyMediumGray.opacity(0.6))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Progress Indicator
                    HStack(spacing: 8) {
                        Text("Stop")
                            .font(.caption2)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text("\(navigationManager.currentLocationIndex + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(trip.color.color)
                        
                        Text("of")
                            .font(.caption2)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text("\(navigationManager.tripLocations.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.spotifyDarkGray.opacity(0.95))
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Navigation Turn Icon
struct NavigationTurnIcon: View {
    let instruction: String
    
    private var iconName: String {
        let lowercased = instruction.lowercased()
        
        if lowercased.contains("left") {
            return "arrow.turn.up.left"
        } else if lowercased.contains("right") {
            return "arrow.turn.up.right"
        } else if lowercased.contains("straight") || lowercased.contains("continue") {
            return "arrow.up"
        } else if lowercased.contains("merge") {
            return "arrow.merge"
        } else if lowercased.contains("exit") {
            return "arrow.up.right.circle"
        } else if lowercased.contains("arrive") || lowercased.contains("destination") {
            return "mappin.circle.fill"
        } else if lowercased.contains("u-turn") || lowercased.contains("uturn") {
            return "arrow.uturn.up"
        } else {
            return "arrow.up"
        }
    }
    
    var body: some View {
        Image(systemName: iconName)
    }
}

// MARK: - Navigation Route Overview
struct NavigationRouteOverview: View {
    var navigationManager: NavigationManager
    let trip: Trip
    let locations: [LocationData]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Trip Header
                        VStack(spacing: 12) {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(trip.color.color)
                            
                            Text(trip.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                // Total Distance
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.caption)
                                    Text(formatTotalDistance())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.spotifyGreen)
                                
                                // Estimated Time
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    Text(formatTotalTime())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.spotifyTextGray)
                                
                                // Stops
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin")
                                        .font(.caption)
                                    Text("\(locations.count) stops")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.spotifyTextGray)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Route List
                        VStack(spacing: 0) {
                            ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                                NavigationRouteStopRow(
                                    location: location,
                                    index: index,
                                    tripColor: trip.color.color,
                                    isCompleted: index < navigationManager.currentLocationIndex,
                                    isCurrent: index == navigationManager.currentLocationIndex,
                                    isLast: index == locations.count - 1
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Route Overview")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
    
    private func formatTotalDistance() -> String {
        let totalDistance = navigationManager.allRoutes.reduce(0) { $0 + $1.distance }
        return navigationManager.formatDistance(totalDistance)
    }
    
    private func formatTotalTime() -> String {
        let totalTime = navigationManager.allRoutes.reduce(0) { $0 + $1.expectedTravelTime }
        return navigationManager.formatTime(totalTime)
    }
}

// MARK: - Navigation Route Stop Row
struct NavigationRouteStopRow: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Step indicator with connection line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.gray : (isCurrent ? tripColor : tripColor.opacity(0.3)))
                        .frame(width: isCurrent ? 36 : 32, height: isCurrent ? 36 : 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.gray : tripColor.opacity(0.3))
                        .frame(width: 2, height: 50)
                }
            }
            
            // Location info
            VStack(alignment: .leading, spacing: 6) {
                if isCurrent {
                    Text("NAVIGATING TO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(tripColor)
                }
                
                Text(location.address)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isCompleted ? .spotifyTextGray : .white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let comment = location.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.spotifyTextGray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, isLast ? 0 : 8)
        }
    }
}

#Preview {
    TripNavigationView(
        trip: Trip(name: "Weekend Adventure", color: .green),
        locations: [
            LocationData(
                address: "Apple Park, Cupertino, CA",
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                altitude: 56.7
            )
        ],
        startLocationIndex: 0,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
