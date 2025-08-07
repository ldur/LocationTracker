// /Views/Trips/TripNavigationView.swift - Complete Google Maps Style Navigation - FIXED

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
            // FIXED: Simplified Map view to avoid compiler timeout
            navigationMapView
            
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
            NavigationRouteOverviewSheet(
                navigationManager: navigationManager,
                trip: trip,
                locations: sortedLocations
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - FIXED: Broken out Map View to avoid compiler timeout
    private var navigationMapView: some View {
        Map(position: $cameraPosition) {
            // Route layers
            routeOverlays
            
            // User location marker
            userLocationMarker
            
            // Destination markers
            destinationMarkers
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
    }
    
    // MARK: - FIXED: Route overlays as separate computed property
    @MapContentBuilder
    private var routeOverlays: some MapContent {
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
            if let userLocation = navigationManager.userLocation,
               let progressPolyline = RouteHelper.createTraveledPolyline(route: route, userLocation: userLocation) {
                MapPolyline(progressPolyline)
                    .stroke(Color.blue.opacity(0.7), style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round,
                        lineJoin: .round
                    ))
            }
        }
    }
    
    // MARK: - FIXED: User location as separate computed property
    @MapContentBuilder
    private var userLocationMarker: some MapContent {
        if let userLocation = navigationManager.userLocation {
            Annotation("", coordinate: userLocation.coordinate) {
                GoogleMapsStyleUserMarker(
                    heading: navigationManager.userHeading?.trueHeading,
                    isOnRoute: navigationManager.isOnRoute
                )
            }
        }
    }
    
    // MARK: - FIXED: Destination markers as separate computed property
    @MapContentBuilder
    private var destinationMarkers: some MapContent {
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
}

// MARK: - FIXED: Added missing NavigationRouteOverviewSheet (Simplified)
struct NavigationRouteOverviewSheet: View {
    let navigationManager: NavigationManager
    let trip: Trip
    let locations: [LocationData]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                scrollContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    toolbarTitle
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - View Components
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.spotifyDarkGray, Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                routeSummarySection
                remainingStopsSection
                completedStopsSection
            }
            .padding(.bottom, 20)
        }
    }
    
    private var toolbarTitle: some View {
        VStack(spacing: 2) {
            Text("Route Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(trip.name)
                .font(.caption)
                .foregroundColor(.spotifyTextGray)
        }
    }
    
    private var routeSummarySection: some View {
        NavigationSummaryCard(
            trip: trip,
            totalDistance: navigationManager.distanceToDestination,
            totalTime: navigationManager.timeToDestination,
            completedStops: navigationManager.currentLocationIndex,
            totalStops: locations.count
        )
        .padding(.horizontal, 20)
    }
    
    private var remainingStopsSection: some View {
        RemainingStopsSection(
            navigationManager: navigationManager,
            trip: trip
        )
    }
    
    private var completedStopsSection: some View {
        CompletedStopsSection(
            navigationManager: navigationManager,
            trip: trip
        )
    }
}

// MARK: - Remaining Stops Section Component
struct RemainingStopsSection: View {
    let navigationManager: NavigationManager
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            stopsList
        }
    }
    
    private var sectionHeader: some View {
        Text("Remaining Stops")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
    
    private var stopsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(navigationManager.getRemainingLocations().enumerated()), id: \.element.id) { index, location in
                RouteStopRow(
                    location: location,
                    index: navigationManager.currentLocationIndex + index + 1,
                    tripColor: trip.color.color,
                    isNext: index == 0
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Completed Stops Section Component
struct CompletedStopsSection: View {
    let navigationManager: NavigationManager
    let trip: Trip
    
    private var completedLocations: [LocationData] {
        navigationManager.getCompletedLocations()
    }
    
    var body: some View {
        if !completedLocations.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader
                stopsList
            }
        }
    }
    
    private var sectionHeader: some View {
        Text("Completed Stops")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
    }
    
    private var stopsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(completedLocations.enumerated()), id: \.element.id) { index, location in
                RouteStopRow(
                    location: location,
                    index: index + 1,
                    tripColor: trip.color.color,
                    isCompleted: true
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Route Stop Row Component
struct RouteStopRow: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let isNext: Bool
    let isCompleted: Bool
    
    // Convenience initializers for default values
    init(location: LocationData, index: Int, tripColor: Color, isNext: Bool = false, isCompleted: Bool = false) {
        self.location = location
        self.index = index
        self.tripColor = tripColor
        self.isNext = isNext
        self.isCompleted = isCompleted
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isNext ? tripColor : Color.spotifyTextGray.opacity(0.3)))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isNext ? .white : .spotifyTextGray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location.address)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if isNext {
                    Text("Next destination")
                        .font(.caption)
                        .foregroundColor(tripColor)
                } else if isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Upcoming")
                        .font(.caption)
                        .foregroundColor(.spotifyTextGray)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isNext ? tripColor.opacity(0.1) : Color.spotifyMediumGray.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isNext ? tripColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isNext ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isNext)
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
