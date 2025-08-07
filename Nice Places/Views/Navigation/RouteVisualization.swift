// /Views/Navigation/RouteVisualization.swift - Complete Route Visualization Components

import SwiftUI
import MapKit
import CoreLocation

// MARK: - MKPolyline Extension for Coordinates
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

// MARK: - Route Drawing Helper Functions
// Note: Route drawing is handled directly in the Map view in TripNavigationView.swift
// These helper functions can be used for route calculations

struct RouteHelper {
    static func createTraveledPolyline(route: MKRoute, userLocation: CLLocation) -> MKPolyline? {
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

// MARK: - Advanced Navigation HUD
struct NavigationHUD: View {
    let navigationManager: NavigationManager
    let trip: Trip
    @State private var showingSpeedInfo = false
    @State private var showingRouteOptions = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Top status indicators
            HStack {
                // Speed limit (if available)
                if let speedLimit = navigationManager.getCurrentSpeedLimit() {
                    SpeedLimitView(
                        speedLimit: speedLimit,
                        currentSpeed: navigationManager.getCurrentSpeed()
                    )
                }
                
                // Current speed display
                CurrentSpeedView(
                    currentSpeed: navigationManager.getCurrentSpeed(),
                    speedLimit: navigationManager.getCurrentSpeedLimit()
                )
                
                Spacer()
                
                // Traffic condition
                let traffic = navigationManager.getTrafficCondition()
                if traffic != .normal {
                    TrafficAlertView(
                        condition: traffic,
                        delayMinutes: traffic.delayMinutes
                    )
                }
            }
            
            // Lane guidance (if available)
            if let lanes = navigationManager.getLaneGuidance() {
                LaneGuidanceView(lanes: lanes)
                    .transition(.slide.combined(with: .opacity))
            }
            
            Spacer()
            
            // Bottom control buttons
            HStack(spacing: 16) {
                // Sound toggle
                Button(action: {}) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                // Route options
                Button(action: { showingRouteOptions = true }) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Search/Add stop
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding(16)
        .sheet(isPresented: $showingRouteOptions) {
            RouteOptionsSheet(
                isPresented: $showingRouteOptions,
                navigationManager: navigationManager,
                onRouteSelected: { routeIndex in
                    // Handle route selection
                    print("Selected route: \(routeIndex)")
                }
            )
        }
        .animation(.easeInOut(duration: 0.3), value: navigationManager.getLaneGuidance() != nil)
    }
}

// MARK: - Turn-by-Turn Instruction Card
struct TurnInstructionCard: View {
    let navigationManager: NavigationManager
    let trip: Trip
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main instruction
            HStack(spacing: 16) {
                // Turn icon
                GoogleMapsStyleTurnIcon(instruction: navigationManager.currentInstruction)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 64, height: 64)
                    .background(.blue.opacity(0.1), in: Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Distance to turn
                    Text(navigationManager.formatDistance(navigationManager.distanceToNextTurn))
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    // Instruction text
                    let instruction = navigationManager.getFormattedInstruction()
                    Text(instruction.primary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let secondary = instruction.secondary {
                        Text(secondary)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Expand button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, 20)
                
                // Additional information
                VStack(spacing: 12) {
                    // Next instruction
                    if !navigationManager.nextInstruction.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Then")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(navigationManager.nextInstruction)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Trip progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Trip Progress")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Stop \(navigationManager.currentLocationIndex + 1) of \(navigationManager.tripLocations.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(
                            value: Double(navigationManager.currentLocationIndex + 1),
                            total: Double(navigationManager.tripLocations.count)
                        )
                        .tint(.blue)
                        .scaleEffect(y: 1.5)
                    }
                    
                    // ETA information
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Arrival Time")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let eta = navigationManager.etaToNextLocation {
                                Text(eta, style: .time)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Distance Left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(navigationManager.formatDistance(navigationManager.distanceToDestination))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Arrival Screen
struct ArrivalScreen: View {
    let destination: LocationData
    let trip: Trip
    let arrivalTime: Date
    let navigationManager: NavigationManager
    let onContinue: () -> Void
    let onFinish: () -> Void
    
    @State private var showingCelebration = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.spotifyDarkGray, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success animation
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showingCelebration ? 1.2 : 1.0)
                    
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(showingCelebration ? 1.1 : 1.0)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                        .scaleEffect(showingCelebration ? 1.0 : 0.8)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showingCelebration)
                
                // Arrival info
                VStack(spacing: 16) {
                    Text("You've arrived!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(destination.address)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(Color.spotifyTextGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    Text("Arrived at \(arrivalTime, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(Color.spotifyTextGray)
                }
                
                // Arrival statistics
                if navigationManager.tripLocations.count > 1 {
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("Stop")
                                .font(.caption)
                                .foregroundColor(Color.spotifyTextGray)
                            
                            Text("\(navigationManager.currentLocationIndex + 1)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.spotifyGreen)
                        }
                        
                        VStack(spacing: 4) {
                            Text("of")
                                .font(.caption)
                                .foregroundColor(Color.spotifyTextGray)
                            
                            Text("\(navigationManager.tripLocations.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(Color.spotifyTextGray)
                            
                            let remaining = navigationManager.tripLocations.count - (navigationManager.currentLocationIndex + 1)
                            Text("\(remaining)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.spotifyMediumGray.opacity(0.6))
                    )
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    if navigationManager.currentLocationIndex < navigationManager.tripLocations.count - 1 {
                        Button(action: onContinue) {
                            Text("Continue to Next Stop")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.spotifyGreen, in: RoundedRectangle(cornerRadius: 28))
                        }
                    }
                    
                    Button(action: onFinish) {
                        Text(navigationManager.currentLocationIndex < navigationManager.tripLocations.count - 1 ? "End Navigation" : "Finish Trip")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.spotifyGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.spotifyGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 28))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Trigger celebration animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingCelebration = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Navigation Summary Card
struct NavigationSummaryCard: View {
    let trip: Trip
    let totalDistance: Double
    let totalTime: TimeInterval
    let completedStops: Int
    let totalStops: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trip Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Circle()
                    .fill(trip.color.color)
                    .frame(width: 12, height: 12)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDistance(totalDistance))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(totalTime))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Stops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(completedStops)/\(totalStops)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                
                ProgressView(value: Double(completedStops), total: Double(totalStops))
                    .tint(trip.color.color)
                    .scaleEffect(y: 2)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Enhanced Google Maps Style Turn Icon (with more comprehensive turn detection)
struct GoogleMapsStyleTurnIcon: View {
    let instruction: String
    
    private var iconName: String {
        let lowercased = instruction.lowercased()
        
        // More comprehensive turn detection
        if lowercased.contains("sharp left") || lowercased.contains("hard left") {
            return "arrow.turn.down.left"
        } else if lowercased.contains("sharp right") || lowercased.contains("hard right") {
            return "arrow.turn.down.right"
        } else if lowercased.contains("slight left") || lowercased.contains("bear left") {
            return "arrow.up.left"
        } else if lowercased.contains("slight right") || lowercased.contains("bear right") {
            return "arrow.up.right"
        } else if lowercased.contains("left") {
            return "arrow.turn.up.left"
        } else if lowercased.contains("right") {
            return "arrow.turn.up.right"
        } else if lowercased.contains("straight") || lowercased.contains("continue") || lowercased.contains("proceed") {
            return "arrow.up"
        } else if lowercased.contains("merge") {
            return "point.topleft.down.curvedto.point.bottomright.up"
        } else if lowercased.contains("exit") || lowercased.contains("off-ramp") {
            return "arrow.up.right.circle"
        } else if lowercased.contains("arrive") || lowercased.contains("destination") || lowercased.contains("finish") {
            return "mappin.circle.fill"
        } else if lowercased.contains("u-turn") || lowercased.contains("uturn") || lowercased.contains("turn around") {
            return "arrow.uturn.up"
        } else if lowercased.contains("roundabout") || lowercased.contains("circle") {
            return "arrow.clockwise"
        } else if lowercased.contains("fork") {
            return "arrow.triangle.branch"
        } else if lowercased.contains("ramp") {
            return "arrow.up.right"
        } else {
            return "arrow.up"
        }
    }
    
    var body: some View {
        Image(systemName: iconName)
    }
}

// MARK: - Voice Instructions Display
struct VoiceInstructionDisplay: View {
    let instruction: String
    let isActive: Bool
    @State private var waveAnimation = false
    
    var body: some View {
        if isActive {
            HStack(spacing: 12) {
                // Voice wave animation
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.blue)
                            .frame(width: 3, height: waveAnimation ? 12 : 6)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: waveAnimation
                            )
                    }
                }
                .frame(width: 20, height: 12)
                
                Text(instruction)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .transition(.slide.combined(with: .opacity))
            .onAppear {
                waveAnimation = true
            }
            .onDisappear {
                waveAnimation = false
            }
        }
    }
}
