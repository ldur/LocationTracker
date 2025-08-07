// /Views/Trips/TripNavigationView.swift - Complete Google Maps Style Navigation

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
    
    // Arrival screen state
    @State private var showingArrivalScreen = false
    @State private var arrivalTime: Date?
    @State private var currentDestination: LocationData?
    
    // Voice instructions
    @State private var showingVoiceInstruction = false
    @State private var voiceInstructionText = ""
    
    private var sortedLocations: [LocationData] {
        locations.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        ZStack {
            // Enhanced Google Maps Style Navigation Map
            Map(position: $cameraPosition) {
                // Route Path - Google Maps Style with multiple layers
                if let route = navigationManager.currentRoute {
                    // Background route line (white outline)
                    MapPolyline(route.polyline)
                        .stroke(.white, style: StrokeStyle(
                            lineWidth: 14,
                            lineCap: .round,
                            lineJoin: .round
                        ))
                    
                    // Main route line (blue)
                    MapPolyline(route.polyline)
                        .stroke(Color.blue, style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round,
                            lineJoin: .round
                        ))
                    
                    // Route progress indicator
                    if let userLocation = navigationManager.userLocation {
                        let progressPolyline = RouteHelper.createTraveledPolyline(route: route, userLocation: userLocation)
                        if let progressPolyline = progressPolyline {
                            MapPolyline(progressPolyline)
                                .stroke(Color.blue.opacity(0.7), style: StrokeStyle(
                                    lineWidth: 10,
                                    lineCap: .round,
                                    lineJoin: .round
                                ))
                        }
                    }
                }
                
                // User Location - Google Maps Style
                if let userLocation = navigationManager.userLocation {
                    Annotation("", coordinate: userLocation.coordinate) {
                        GoogleMapsStyleUserMarker(
                            heading: navigationManager.userHeading?.trueHeading,
                            isOnRoute: navigationManager.isOnRoute
                        )
                    }
                }
                
                // Destination Markers - Google Maps Style
                ForEach(Array(sortedLocations.enumerated()), id: \.element.id) { index, location in
                    let isCompleted = index < navigationManager.currentLocationIndex
                    let isCurrent = index == navigationManager.currentLocationIndex
                    let isFuture = index > navigationManager.currentLocationIndex
                    
                    Annotation(
                        location.address,
                        coordinate: location.coordinate,
                        anchor: .bottom
                    ) {
                        GoogleMapsStyleLocationMarker(
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
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                    .mapControlVisibility(.hidden)
            }
            .ignoresSafeArea()
            .onTapGesture {
                isFollowingUser = false
            }
            
            // Navigation HUD Overlays
            VStack {
                Spacer()
                
                NavigationHUD(
                    navigationManager: navigationManager,
                    trip: trip
                )
                .padding(.bottom, 180) // Space for instruction card
            }
            
            // Google Maps Style Top Bar
            VStack {
                GoogleMapsStyleTopBar(
                    navigationManager: navigationManager,
                    trip: trip,
                    isFollowingUser: isFollowingUser,
                    onExit: { showingExitConfirmation = true },
                    onToggleOverview: { showingRouteOverview.toggle() },
                    onRecenter: {
                        isFollowingUser = true
                        updateCameraToUserLocation()
                    }
                )
                .padding(.top, 50)
                
                // Voice Instruction Display
                if showingVoiceInstruction {
                    VoiceInstructionDisplay(
                        instruction: voiceInstructionText,
                        isActive: showingVoiceInstruction
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // Turn Instruction Card (when not showing arrival)
            if !showingArrivalScreen {
                VStack {
                    Spacer()
                    
                    TurnInstructionCard(
                        navigationManager: navigationManager,
                        trip: trip
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            
            // Arrival Screen Overlay
            if showingArrivalScreen, let destination = currentDestination, let arrival = arrivalTime {
                ArrivalScreen(
                    destination: destination,
                    trip: trip,
                    arrivalTime: arrival,
                    navigationManager: navigationManager,
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showingArrivalScreen = false
                        }
                        Task {
                            await navigationManager.skipToNextLocation()
                        }
                    },
                    onFinish: {
                        navigationManager.stopNavigation()
                        onDismiss()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
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
        .onChange(of: navigationManager.currentLocationIndex) { oldIndex, newIndex in
            // Check if we've moved to a new location (arrived at destination)
            if newIndex > oldIndex && newIndex <= sortedLocations.count {
                handleArrivalAtDestination()
            }
        }
        .onChange(of: navigationManager.currentInstruction) { _, newInstruction in
            // Trigger voice instruction display
            if !newInstruction.isEmpty && newInstruction != "Calculating route..." {
                triggerVoiceInstruction(newInstruction)
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
    
    // MARK: - Helper Functions
    
    private func handleArrivalAtDestination() {
        // Get the destination we just arrived at
        let arrivedIndex = navigationManager.currentLocationIndex - 1
        if arrivedIndex >= 0 && arrivedIndex < sortedLocations.count {
            currentDestination = sortedLocations[arrivedIndex]
            arrivalTime = Date()
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showingArrivalScreen = true
            }
            
            // Auto-dismiss arrival screen after 8 seconds if not interacted with
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if showingArrivalScreen {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingArrivalScreen = false
                    }
                }
            }
        }
    }
    
    private func triggerVoiceInstruction(_ instruction: String) {
        voiceInstructionText = instruction
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showingVoiceInstruction = true
        }
        
        // Hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingVoiceInstruction = false
            }
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
        withAnimation(.easeInOut(duration: 0.8)) {
            let heading = navigationManager.userHeading?.trueHeading ?? 0
            
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 600, // Google Maps style zoom
                    heading: isFollowingUser ? heading : 0,
                    pitch: 65 // Google Maps style tilt
                )
            )
            
            if isFollowingUser {
                mapRotation = heading
            }
        }
    }
    
    private func createProgressPolyline(route: MKRoute, userLocation: CLLocation) -> MKPolyline? {
        let routeCoordinates = route.polyline.coordinates
        guard !routeCoordinates.isEmpty else { return nil }
        
        // Find the closest point on the route to the user's location
        var closestIndex = 0
        var minDistance = Double.greatestFiniteMagnitude
        
        for (index, coordinate) in routeCoordinates.enumerated() {
            let routeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = userLocation.distance(from: routeLocation)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        // Create polyline from start to user's position
        if closestIndex > 0 {
            let traveledCoordinates = Array(routeCoordinates[0...closestIndex])
            return MKPolyline(coordinates: traveledCoordinates, count: traveledCoordinates.count)
        }
        
        return nil
    }
}

// MARK: - Google Maps Style User Marker
struct GoogleMapsStyleUserMarker: View {
    let heading: Double?
    let isOnRoute: Bool
    
    var body: some View {
        ZStack {
            // Outer ring - Google Maps style
            Circle()
                .fill(.white)
                .frame(width: 24, height: 24)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Direction indicator
            if let heading = heading {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(heading))
            } else {
                Circle()
                    .fill(.blue)
                    .frame(width: 16, height: 16)
            }
            
            // Accuracy ring - Google Maps style
            Circle()
                .stroke(.blue.opacity(0.3), lineWidth: 1)
                .frame(width: 40, height: 40)
        }
        .scaleEffect(isOnRoute ? 1.0 : 1.2)
        .animation(.easeInOut(duration: 0.3), value: isOnRoute)
    }
}

// MARK: - Google Maps Style Location Marker
struct GoogleMapsStyleLocationMarker: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let isCompleted: Bool
    let isCurrent: Bool
    let isFuture: Bool
    
    var body: some View {
        ZStack {
            if isCurrent {
                // Pulsing animation for current destination
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.5)
                    .opacity(0.8)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
            
            // Pin shadow
            Ellipse()
                .fill(.black.opacity(0.2))
                .frame(width: isCurrent ? 20 : 16, height: isCurrent ? 6 : 4)
                .offset(y: isCurrent ? 25 : 20)
            
            // Main pin
            ZStack {
                RoundedRectangle(cornerRadius: isCurrent ? 20 : 16)
                    .fill(.white)
                    .frame(width: isCurrent ? 40 : 32, height: isCurrent ? 40 : 32)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: isCurrent ? 16 : 14, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(index)")
                        .font(.system(size: isCurrent ? 16 : 14, weight: .bold))
                        .foregroundColor(isCurrent ? .blue : tripColor)
                }
            }
            
            if isCurrent {
                VStack {
                    Spacer()
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                        .offset(y: 28)
                }
            }
        }
        .scaleEffect(isCurrent ? 1.1 : (isCompleted ? 0.9 : 1.0))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isCurrent)
    }
}

// MARK: - Google Maps Style Top Bar
struct GoogleMapsStyleTopBar: View {
    var navigationManager: NavigationManager
    let trip: Trip
    let isFollowingUser: Bool
    let onExit: () -> Void
    let onToggleOverview: () -> Void
    let onRecenter: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Exit Button
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            // ETA and Distance Card
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if let eta = navigationManager.etaToNextLocation {
                        Text(eta, style: .time)
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                    } else {
                        Text("--:--")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text(navigationManager.formatDistance(navigationManager.distanceToNextLocation))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // Traffic indicator dot
                        let traffic = navigationManager.getTrafficCondition()
                        Circle()
                            .fill(traffic.color)
                            .frame(width: 4, height: 4)
                    }
                }
                
                Spacer()
                
                // Route overview button
                Button(action: onToggleOverview) {
                    Image(systemName: "map")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Recenter Button
            Button(action: onRecenter) {
                Image(systemName: isFollowingUser ? "location.fill" : "location")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFollowingUser ? .blue : .primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 16)
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
