// /Views/Navigation/NavigationEnhancements.swift - Complete Navigation Enhancements

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Enhanced Navigation Manager Extensions
extension NavigationManager {
    
    // MARK: - Google Maps Style Route Progress
    func getRouteProgress() -> Double {
        guard let route = currentRoute,
              let userLocation = userLocation else { return 0.0 }
        
        let routeDistance = route.distance
        let remainingDistance = distanceToDestination
        let progressDistance = routeDistance - remainingDistance
        
        return min(1.0, max(0.0, progressDistance / routeDistance))
    }
    
    // MARK: - Enhanced Instruction Formatting
    func getFormattedInstruction() -> (primary: String, secondary: String?) {
        let instruction = currentInstruction
        
        if instruction.isEmpty {
            return ("Calculating route...", nil)
        }
        
        // Split long instructions into primary and secondary parts
        let words = instruction.components(separatedBy: " ")
        if words.count > 6 {
            let primaryWords = Array(words.prefix(4))
            let secondaryWords = Array(words.dropFirst(4))
            return (primaryWords.joined(separator: " "), secondaryWords.joined(separator: " "))
        }
        
        return (instruction, nil)
    }
    
    // MARK: - Lane Guidance (Simulated)
    func getLaneGuidance() -> [LaneInfo]? {
        // This would be populated from actual route data
        // For demo purposes, returning simulated data for certain instructions
        let instruction = currentInstruction.lowercased()
        
        if instruction.contains("turn left") {
            return [
                LaneInfo(direction: .straight, isRecommended: false),
                LaneInfo(direction: .left, isRecommended: true),
                LaneInfo(direction: .left, isRecommended: true)
            ]
        } else if instruction.contains("turn right") {
            return [
                LaneInfo(direction: .right, isRecommended: true),
                LaneInfo(direction: .right, isRecommended: true),
                LaneInfo(direction: .straight, isRecommended: false)
            ]
        } else if instruction.contains("merge") {
            return [
                LaneInfo(direction: .straight, isRecommended: true),
                LaneInfo(direction: .slightRight, isRecommended: true),
                LaneInfo(direction: .right, isRecommended: false)
            ]
        }
        
        return nil
    }
    
    // MARK: - Speed Limit Information (Simulated)
    func getCurrentSpeedLimit() -> Int? {
        // This would come from map data
        // For demo purposes, returning simulated speed limits
        let random = Int.random(in: 0...10)
        if random < 3 {
            return nil // No speed limit data
        } else if random < 6 {
            return 50 // City streets
        } else if random < 8 {
            return 80 // Main roads
        } else {
            return 110 // Highways
        }
    }
    
    // MARK: - Traffic Information (Simulated)
    func getTrafficCondition() -> TrafficCondition {
        // This would be calculated from real traffic data
        let random = Int.random(in: 0...10)
        if random < 6 {
            return .normal
        } else if random < 8 {
            return .light
        } else if random < 9 {
            return .heavy
        } else {
            return .severe
        }
    }
    
    // MARK: - Current Speed (Simulated)
    func getCurrentSpeed() -> Double? {
        // This would come from GPS data
        return Double.random(in: 40...70) // km/h
    }
    
    // MARK: - Parking Information (Simulated)
    func getParkingInfo(for location: LocationData) -> String? {
        let parkingOptions = [
            "Street parking available",
            "Paid parking nearby",
            "Free parking available",
            "Limited parking",
            nil, nil // No parking info
        ]
        return parkingOptions.randomElement() ?? nil
    }
}

// MARK: - Traffic Condition Enum
enum TrafficCondition {
    case light, normal, heavy, severe
    
    var color: Color {
        switch self {
        case .light: return .green
        case .normal: return .green
        case .heavy: return .orange
        case .severe: return .red
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Light traffic"
        case .normal: return "Normal traffic"
        case .heavy: return "Heavy traffic"
        case .severe: return "Severe traffic"
        }
    }
    
    var delayMinutes: Int? {
        switch self {
        case .light, .normal: return nil
        case .heavy: return Int.random(in: 2...5)
        case .severe: return Int.random(in: 5...15)
        }
    }
}

// MARK: - Lane Information
struct LaneInfo {
    let direction: LaneDirection
    let isRecommended: Bool
}

enum LaneDirection {
    case straight, left, right, slightLeft, slightRight, uturn
    
    var icon: String {
        switch self {
        case .straight: return "arrow.up"
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        case .slightLeft: return "arrow.up.left"
        case .slightRight: return "arrow.up.right"
        case .uturn: return "arrow.uturn.up"
        }
    }
}

// MARK: - Speed Limit Display
struct SpeedLimitView: View {
    let speedLimit: Int?
    let currentSpeed: Double?
    
    var isOverLimit: Bool {
        guard let limit = speedLimit, let current = currentSpeed else { return false }
        return current > Double(limit) + 5 // 5 km/h tolerance
    }
    
    var body: some View {
        if let limit = speedLimit {
            VStack(spacing: 2) {
                Text("SPEED")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
                
                Text("\(limit)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text("LIMIT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black)
            }
            .frame(width: 40, height: 50)
            .background(.white, in: RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isOverLimit ? .red : .red, lineWidth: 3)
            )
            .scaleEffect(isOverLimit ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isOverLimit)
        }
    }
}

// MARK: - Lane Guidance View
struct LaneGuidanceView: View {
    let lanes: [LaneInfo]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(lanes.enumerated()), id: \.offset) { index, lane in
                VStack(spacing: 4) {
                    Image(systemName: lane.direction.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(lane.isRecommended ? .blue : .secondary)
                    
                    Rectangle()
                        .fill(lane.isRecommended ? .blue : .secondary)
                        .frame(width: 20, height: 3)
                        .cornerRadius(1.5)
                }
                .scaleEffect(lane.isRecommended ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: lane.isRecommended)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Traffic Alert Banner
struct TrafficAlertView: View {
    let condition: TrafficCondition
    let delayMinutes: Int?
    
    var body: some View {
        if condition != .normal || delayMinutes != nil {
            HStack(spacing: 8) {
                Circle()
                    .fill(condition.color)
                    .frame(width: 8, height: 8)
                
                Text(condition.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                if let delay = delayMinutes, delay > 0 {
                    Text("• +\(delay) min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Google Maps Style Route Alternative
struct RouteAlternativeView: View {
    let alternativeTime: String
    let savings: String?
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(alternativeTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Bottom Sheet for Route Options
struct RouteOptionsSheet: View {
    @Binding var isPresented: Bool
    let navigationManager: NavigationManager
    let onRouteSelected: (Int) -> Void
    
    @State private var selectedRoute = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Route Options")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Route alternatives (simulated)
                VStack(spacing: 12) {
                    RouteAlternativeView(
                        alternativeTime: navigationManager.formatTime(navigationManager.timeToDestination),
                        savings: nil,
                        isSelected: selectedRoute == 0,
                        onSelect: {
                            selectedRoute = 0
                            onRouteSelected(0)
                        }
                    )
                    
                    RouteAlternativeView(
                        alternativeTime: navigationManager.formatTime(navigationManager.timeToDestination + 300), // +5 min
                        savings: "Avoid tolls",
                        isSelected: selectedRoute == 1,
                        onSelect: {
                            selectedRoute = 1
                            onRouteSelected(1)
                        }
                    )
                    
                    RouteAlternativeView(
                        alternativeTime: navigationManager.formatTime(navigationManager.timeToDestination - 120), // -2 min
                        savings: "2 min faster",
                        isSelected: selectedRoute == 2,
                        onSelect: {
                            selectedRoute = 2
                            onRouteSelected(2)
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Google Maps Style Search Bar (for destination changes)
struct NavigationSearchBar: View {
    @State private var searchText = ""
    @Binding var isPresented: Bool
    let onDestinationChanged: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for places", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    onDestinationChanged(searchText)
                    isPresented = false
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Arrival Information View
struct ArrivalInfoView: View {
    let destination: LocationData
    let estimatedArrival: Date
    let parkingInfo: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Destination info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arriving at")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(destination.address)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Arrival time
            HStack {
                Text("ETA")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(estimatedArrival, style: .time)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Parking info (if available)
            if let parking = parkingInfo {
                HStack {
                    Image(systemName: "car")
                        .foregroundColor(.blue)
                    
                    Text(parking)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Current Speed Display
struct CurrentSpeedView: View {
    let currentSpeed: Double?
    let speedLimit: Int?
    
    var isOverLimit: Bool {
        guard let speed = currentSpeed, let limit = speedLimit else { return false }
        return speed > Double(limit) + 5 // 5 km/h tolerance
    }
    
    var body: some View {
        if let speed = currentSpeed {
            VStack(spacing: 4) {
                Text("\(Int(speed))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isOverLimit ? .red : .primary)
                
                Text("km/h")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, height: 60)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(isOverLimit ? .red : .clear, lineWidth: 2)
            )
            .scaleEffect(isOverLimit ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isOverLimit)
        }
    }
}
