// /Views/Components/NavigationLauncher.swift

import SwiftUI
import CoreLocation

// MARK: - Navigation Launcher Sheet
struct NavigationLauncherSheet: View {
    let trip: Trip
    let locations: [LocationData]
    let onStartNavigation: (Int) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedStartLocation = 0
    @State private var transportMode: NavigationTransportMode = .auto
    
    private var sortedLocations: [LocationData] {
        locations.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var estimatedTotalTime: String {
        // Rough estimation based on transport mode and location count
        let avgTimePerStop: TimeInterval = transportMode == .walking ? 1200 : 600 // 20min walking, 10min driving
        let totalTime = Double(sortedLocations.count) * avgTimePerStop
        
        if totalTime < 3600 {
            return "\(Int(totalTime / 60)) min"
        } else {
            let hours = Int(totalTime / 3600)
            let minutes = Int((totalTime.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
    
    enum NavigationTransportMode {
        case walking, driving, auto
        
        var icon: String {
            switch self {
            case .walking: return "figure.walk"
            case .driving: return "car.fill"
            case .auto: return "gear"
            }
        }
        
        var title: String {
            switch self {
            case .walking: return "Walking"
            case .driving: return "Driving"
            case .auto: return "Auto"
            }
        }
        
        var description: String {
            switch self {
            case .walking: return "Best for city tours"
            case .driving: return "Best for road trips"
            case .auto: return "Based on trip type"
            }
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [trip.color.color, trip.color.color.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Start Navigation")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(trip.name)
                                    .font(.subheadline)
                                    .foregroundColor(trip.color.color)
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin")
                                            .font(.caption)
                                        Text("\(sortedLocations.count) stops")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.spotifyTextGray)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                        Text("~\(estimatedTotalTime)")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.spotifyTextGray)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Transport Mode Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Transport Mode")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 12) {
                                ForEach([NavigationTransportMode.auto, .driving, .walking], id: \.self) { mode in
                                    TransportModeButton(
                                        mode: mode,
                                        isSelected: transportMode == mode,
                                        tripType: trip.autoSaveConfig.tripType,
                                        onSelect: { transportMode = mode }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Starting Location Selection
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Start From")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if selectedStartLocation > 0 {
                                    Text("Skipping \(selectedStartLocation) location\(selectedStartLocation == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 8) {
                                    ForEach(Array(sortedLocations.enumerated()), id: \.element.id) { index, location in
                                        NavigationStartLocationRow(
                                            location: location,
                                            index: index,
                                            tripColor: trip.color.color,
                                            isSelected: selectedStartLocation == index,
                                            onSelect: {
                                                selectedStartLocation = index
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .frame(maxHeight: 300)
                        }
                        
                        // Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.spotifyGreen)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Navigation Features")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("Turn-by-turn directions to each location")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyTextGray)
                                }
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(icon: "location.north.fill", text: "Real-time GPS navigation")
                                FeatureRow(icon: "arrow.triangle.turn.up.right.circle", text: "Voice-guided directions")
                                FeatureRow(icon: "map", text: "Automatic rerouting if you go off course")
                                FeatureRow(icon: "clock", text: "ETA for each destination")
                                FeatureRow(icon: "forward.fill", text: "Skip locations if needed")
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.spotifyMediumGray.opacity(0.6))
                        )
                        .padding(.horizontal, 24)
                        
                        // Start Button
                        Button(action: {
                            onStartNavigation(selectedStartLocation)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.north.fill")
                                    .font(.title2)
                                
                                Text("Start Navigation")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(trip.color.color)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.spotifyTextGray)
                }
            }
        }
    }
}

// MARK: - Transport Mode Button
struct TransportModeButton: View {
    let mode: NavigationLauncherSheet.NavigationTransportMode
    let isSelected: Bool
    let tripType: TripType
    let onSelect: () -> Void
    
    private var isRecommended: Bool {
        switch mode {
        case .auto:
            return true
        case .walking:
            return tripType == .walking
        case .driving:
            return tripType == .car
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.spotifyGreen : Color.spotifyMediumGray.opacity(0.6))
                        .frame(height: 80)
                    
                    VStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.title2)
                            .foregroundColor(isSelected ? .black : .white)
                        
                        Text(mode.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .black : .white)
                        
                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .foregroundColor(isSelected ? .black.opacity(0.7) : .spotifyGreen)
                        }
                    }
                }
                
                Text(mode.description)
                    .font(.caption2)
                    .foregroundColor(.spotifyTextGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation Start Location Row
struct NavigationStartLocationRow: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? tripColor : Color.spotifyTextGray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(tripColor)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Step number
                ZStack {
                    Circle()
                        .fill(tripColor.opacity(isSelected ? 1.0 : 0.3))
                        .frame(width: 32, height: 32)
                    
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.address)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if index == 0 {
                        Text("First location")
                            .font(.caption)
                            .foregroundColor(tripColor)
                    } else if index > 0 && isSelected {
                        Text("Skip first \(index) location\(index == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tripColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? tripColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.spotifyGreen)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.spotifyTextGray)
            
            Spacer()
        }
    }
}

// MARK: - Quick Navigation Button (for trip views)
struct QuickNavigationButton: View {
    let trip: Trip
    let locationCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "location.north.circle.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Navigate Trip Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(locationCount) stops • Turn-by-turn directions")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.6)
            }
            .foregroundColor(.black)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(trip.color.color)
            )
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    NavigationLauncherSheet(
        trip: Trip(name: "Weekend Adventure", color: .green),
        locations: [
            LocationData(
                address: "Apple Park, Cupertino, CA",
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                altitude: 56.7
            ),
            LocationData(
                address: "Stanford University, Stanford, CA",
                coordinate: CLLocationCoordinate2D(latitude: 37.4275, longitude: -122.1697),
                altitude: 30.0
            )
        ],
        onStartNavigation: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
