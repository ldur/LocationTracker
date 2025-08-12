// /Views/Components/TripComponents.swift

import SwiftUI
import CoreLocation

// MARK: - Active Trip Banner
struct ActiveTripBanner: View {
    let trip: Trip
    let locationCount: Int
    let locations: [LocationData] // NEW: Add locations data
    let onTap: () -> Void
    let onEnd: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Trip Color Indicator
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [trip.color.color, trip.color.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(locationCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    )
                
                // Trip Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(trip.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Active indicator with auto-save status
                        HStack(spacing: 4) {
                            Circle()
                                .fill(trip.color.color)
                                .frame(width: 8, height: 8)
                            
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(trip.color.color)
                            
                            // Auto-save indicator with trip type
                            if trip.autoSaveConfig.isEnabled {
                                Image(systemName: trip.autoSaveConfig.tripType.icon)
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Started")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(trip.startDate, style: .relative)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Locations")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text("\(locationCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        // NEW: Start location indicator
                        let locationInfo = trip.getStartAndEndLocationInfo(from: locations)
                        if locationInfo.hasStart {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                        .foregroundColor(.spotifyGreen)
                                    Text("Set")
                                        .font(.caption2)
                                        .foregroundColor(.spotifyGreen)
                                }
                            }
                        }
                        
                        // Enhanced auto-save status with trip type
                        if trip.autoSaveConfig.isEnabled {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mode")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                
                                HStack(spacing: 2) {
                                    Text(trip.autoSaveConfig.tripType.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.spotifyGreen)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // End Trip Button
                Button(action: onEnd) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.spotifyMediumGray.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(trip.color.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: Trip
    let statistics: TripStatistics
    let locations: [LocationData] // NEW: Add locations data
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Image(systemName: trip.statusIcon)
                                .font(.caption)
                                .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                            
                            Text(trip.status)
                                .font(.caption)
                                .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(trip.durationDescription)
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            // Enhanced auto-save indicator with trip type
                            if trip.autoSaveConfig.isEnabled {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Image(systemName: trip.autoSaveConfig.tripType.icon)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                                
                                Text(trip.autoSaveConfig.tripType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Trip Color Badge
                    Circle()
                        .fill(trip.color.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(trip.name.prefix(1)).uppercased())
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                
                // NEW: Start/End Location Indicator
                let locationInfo = trip.getStartAndEndLocationInfo(from: locations)
                if locationInfo.hasStart || locationInfo.hasEnd {
                    HStack(spacing: 12) {
                        if locationInfo.hasStart {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                                Text("Start")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                        
                        if locationInfo.hasStart && locationInfo.hasEnd {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(.spotifyTextGray)
                        }
                        
                        if locationInfo.hasEnd {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                                Text("End")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                        
                        Spacer()
                        
                        // Show completion indicator
                        if locationInfo.hasStart && locationInfo.hasEnd {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                                Text("Complete")
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.spotifyGreen.opacity(0.1))
                    )
                }
                
                // Statistics Row
                HStack(spacing: 0) {
                    StatisticView(
                        title: "Locations",
                        value: "\(statistics.totalLocations)",
                        icon: "location"
                    )
                    
                    Rectangle()
                        .fill(Color.spotifyTextGray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    StatisticView(
                        title: "Photos",
                        value: "\(statistics.totalPhotos)",
                        icon: "photo"
                    )
                    
                    Rectangle()
                        .fill(Color.spotifyTextGray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    StatisticView(
                        title: "Distance",
                        value: formatDistance(statistics.distanceCovered),
                        icon: "point.topleft.down.curvedto.point.bottomright.up"
                    )
                }
                
                // Description (if available)
                if let description = trip.tripDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.spotifyMediumGray.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(trip.color.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Statistic View Helper
struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.spotifyGreen)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.spotifyTextGray)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Start Trip Sheet with Trip Type Storage
struct StartTripSheet: View {
    let onStartTrip: (String, String?, Trip.TripColor, AutoSaveConfiguration, CLLocation?, String?) -> Void
    let currentLocation: CLLocation? // NEW: Add current location
    let currentAddress: String? // NEW: Add current address
    
    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var selectedColor: Trip.TripColor = .green
    @State private var showDescription = false
    @State private var autoSaveConfig = AutoSaveConfiguration()
    @State private var showAutoSaveConfig = false
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.spotifyGreen)
                            
                            Text("Start New Trip")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Begin tracking your journey")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                        }
                        .padding(.top, 20)
                        
                        // NEW: Show location status
                        if currentLocation == nil {
                            HStack {
                                Image(systemName: "location.slash")
                                    .foregroundColor(.orange)
                                Text("Location not available - trip will start without initial location")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 24)
                        } else {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.spotifyGreen)
                                Text("Current location will be added as trip start point")
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        VStack(spacing: 20) {
                            // Trip Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trip Name")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                TextField("Weekend Adventure, Business Trip...", text: $tripName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyLightGray)
                                    )
                                    .focused($isNameFieldFocused)
                            }
                            
                            // Trip Color
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trip Category")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                    ForEach(Trip.TripColor.allCases, id: \.self) { color in
                                        Button(action: {
                                            selectedColor = color
                                        }) {
                                            VStack(spacing: 8) {
                                                Circle()
                                                    .fill(color.color)
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                                    )
                                                
                                                Text(color.displayName)
                                                    .font(.caption2)
                                                    .foregroundColor(selectedColor == color ? .white : .spotifyTextGray)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            // Enhanced Auto-Save Configuration Section
                            VStack(spacing: 16) {
                                // Auto-Save Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Automatic Location Saving")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("Save locations automatically during your trip")
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $autoSaveConfig.isEnabled)
                                        .tint(.spotifyGreen)
                                }
                                
                                // Auto-Save Configuration (when enabled)
                                if autoSaveConfig.isEnabled {
                                    AutoSaveConfigurationView(config: $autoSaveConfig, isExpanded: $showAutoSaveConfig)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.spotifyMediumGray.opacity(0.6))
                            )
                            
                            // Optional Description
                            if !showDescription {
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        showDescription = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle")
                                            .font(.subheadline)
                                        Text("Add description (optional)")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.spotifyGreen)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Description")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button("Remove") {
                                            withAnimation(.easeInOut) {
                                                showDescription = false
                                                tripDescription = ""
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    TextField("What's this trip about?", text: $tripDescription, axis: .vertical)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.spotifyLightGray)
                                        )
                                        .lineLimit(3...5)
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.spotifyTextGray)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") {
                        let finalDescription = tripDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        onStartTrip(
                            tripName,
                            finalDescription.isEmpty ? nil : finalDescription,
                            selectedColor,
                            autoSaveConfig,
                            currentLocation,
                            currentAddress
                        )
                        dismiss()
                    }
                    .foregroundColor(tripName.trimmingCharacters(in: .whitespaces).isEmpty ? .spotifyTextGray : .spotifyGreen)
                    .disabled(tripName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            isNameFieldFocused = true
        }
    }
}

// MARK: - FIXED: Auto-Save Configuration View - Preserves Trip Type
struct AutoSaveConfigurationView: View {
    @Binding var config: AutoSaveConfiguration
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Configuration Toggle Button
            if !isExpanded {
                Button(action: {
                    withAnimation(.easeInOut) {
                        isExpanded = true
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .font(.subheadline)
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Configure auto-save settings")
                            .font(.subheadline)
                            .foregroundColor(.spotifyGreen)
                        
                        // Show current trip type if not custom
                        if config.tripType != .custom {
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(config.tripType.emoji)
                                    .font(.caption)
                                Text(config.tripType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.spotifyGreen)
                    }
                }
            } else {
                // Expanded Configuration
                VStack(spacing: 16) {
                    // Header with collapse button
                    HStack {
                        Text("Auto-Save Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                        }
                    }
                    
                    // Enhanced Preset Buttons with Trip Type Display
                    VStack(spacing: 12) {
                        HStack {
                            Text("Trip Type")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Current trip type indicator
                            HStack(spacing: 4) {
                                Image(systemName: config.tripType.icon)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                                Text(config.tripType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            EnhancedPresetButton(title: "Walking", emoji: "🚶", preset: .walking, currentConfig: $config)
                            EnhancedPresetButton(title: "Bicycle", emoji: "🚴", preset: .bicycle, currentConfig: $config)
                            EnhancedPresetButton(title: "Car", emoji: "🚗", preset: .car, currentConfig: $config)
                        }
                    }
                    
                    Divider()
                        .background(Color.spotifyTextGray.opacity(0.3))
                    
                    // Road Change Configuration - FIXED: No automatic trip type change
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save on Road Change")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Automatically save when moving to different streets")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $config.saveOnRoadChange)
                                .tint(.spotifyGreen)
                                // REMOVED: onChange that was setting tripType to .custom
                        }
                        
                        if config.saveOnRoadChange {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Minimum Distance: \(Int(config.minimumDistanceMeters))m")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Slider(
                                    value: $config.minimumDistanceMeters,
                                    in: 50...1000,
                                    step: 25
                                )
                                .tint(.spotifyGreen)
                                // REMOVED: onChange that was setting tripType to .custom
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.spotifyTextGray.opacity(0.3))
                    
                    // Time Interval Configuration - FIXED: No automatic trip type change
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save on Time Interval")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Automatically save at regular time intervals")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $config.saveOnTimeInterval)
                                .tint(.spotifyGreen)
                                // REMOVED: onChange that was setting tripType to .custom
                        }
                        
                        if config.saveOnTimeInterval {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Minutes")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                    
                                    Picker("Minutes", selection: $config.timeIntervalMinutes) {
                                        ForEach(0...59, id: \.self) { minute in
                                            Text("\(minute)").tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    // REMOVED: onChange that was setting tripType to .custom
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Seconds")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                    
                                    Picker("Seconds", selection: $config.timeIntervalSeconds) {
                                        ForEach([0, 15, 30, 45], id: \.self) { second in
                                            Text("\(second)").tag(second)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    // REMOVED: onChange that was setting tripType to .custom
                                }
                            }
                            
                            // Time validation
                            if !config.isValidTimeInterval {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("Time interval must be between 30 seconds and 1 hour")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

// MARK: - Enhanced Preset Button with Trip Type Storage
struct EnhancedPresetButton: View {
    let title: String
    let emoji: String
    let preset: AutoSaveConfiguration
    @Binding var currentConfig: AutoSaveConfiguration
    
    var isSelected: Bool {
        currentConfig.tripType == preset.tripType
    }
    
    var body: some View {
        Button(action: {
            // Apply the preset configuration including the trip type
            currentConfig = preset
        }) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .black : .spotifyGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.spotifyGreen : Color.spotifyGreen.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Preset Button (for backward compatibility)
struct PresetButton: View {
    let title: String
    let preset: AutoSaveConfiguration
    @Binding var currentConfig: AutoSaveConfiguration
    
    var isSelected: Bool {
        currentConfig.matchesPreset(preset)
    }
    
    var body: some View {
        Button(action: {
            currentConfig = preset
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .spotifyGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.spotifyGreen : Color.spotifyGreen.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trip Assignment Sheet
struct TripAssignmentSheet: View {
    let location: LocationData
    let availableTrips: [Trip]
    let onAssignToTrip: (Trip) -> Void
    let onCreateNewTrip: () -> Void
    
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
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.branch")
                            .font(.system(size: 50))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Add to Trip")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Choose a trip for this location")
                            .font(.subheadline)
                            .foregroundColor(.spotifyTextGray)
                        
                        // Location preview
                        Text(location.address)
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    if availableTrips.isEmpty {
                        // No trips available
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.spotifyTextGray)
                            
                            Text("No trips yet")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Create your first trip to get started")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Available trips
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(availableTrips, id: \.id) { trip in
                                    TripSelectionRow(
                                        trip: trip,
                                        onSelect: {
                                            onAssignToTrip(trip)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            onCreateNewTrip()
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.headline)
                                
                                Text("Create New Trip")
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
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Enhanced Trip Selection Row with Trip Type Display
struct TripSelectionRow: View {
    let trip: Trip
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Trip indicator
                Circle()
                    .fill(trip.color.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(trip.name.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: trip.statusIcon)
                            .font(.caption)
                            .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                        
                        Text(trip.status)
                            .font(.caption)
                            .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text("\(trip.locationIds.count) locations")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        // Enhanced auto-save indicator with trip type
                        if trip.autoSaveConfig.isEnabled {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            HStack(spacing: 2) {
                                Image(systemName: trip.autoSaveConfig.tripType.icon)
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                                
                                Text(trip.autoSaveConfig.tripType.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.spotifyTextGray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.spotifyLightGray.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let sampleTrip = Trip(name: "Weekend Adventure", description: "Exploring the city", color: .green)
    
    let sampleLocations = [
        LocationData(
            address: "Apple Park, Cupertino, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            altitude: 56.7,
            comment: "Amazing place!",
            photoIdentifiers: ["photo1", "photo2"]
        )
    ]
    
    let sampleStats = TripStatistics(trip: sampleTrip, locations: sampleLocations)
    
    TripCard(
        trip: sampleTrip,
        statistics: sampleStats,
        locations: sampleLocations,
        onTap: {}
    )
    .preferredColorScheme(.dark)
    .padding()
}
