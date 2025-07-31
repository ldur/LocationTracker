// /Views/Trips/TripSuggestionsView.swift

import SwiftUI
import CoreLocation

struct TripSuggestionsView: View {
    @Bindable var tripManager: TripManager
    @Bindable var dataManager: DataManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLocations: Set<UUID> = []
    @State private var showingCreateTripSheet = false
    @State private var tripSuggestions: [TripSuggestion] = []
    
    private var availableLocations: [LocationData] {
        // Show locations not already in trips, or allow multi-trip assignment
        dataManager.savedLocations.sorted { $0.timestamp > $1.timestamp }
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
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .foregroundColor(.spotifyTextGray)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("Create Trip")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if !selectedLocations.isEmpty {
                                Text("\(selectedLocations.count) selected")
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if !selectedLocations.isEmpty {
                                showingCreateTripSheet = true
                            }
                        }) {
                            Text("Create")
                                .fontWeight(.semibold)
                                .foregroundColor(selectedLocations.isEmpty ? .spotifyTextGray : .spotifyGreen)
                        }
                        .disabled(selectedLocations.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Selection Instructions
                    Text("Select locations to include in your trip")
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    
                    // Smart Suggestions Section
                    if !tripSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Smart Suggestions")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(tripSuggestions, id: \.id) { suggestion in
                                        TripSuggestionCard(
                                            suggestion: suggestion,
                                            locations: availableLocations,
                                            isSelected: selectedLocations == Set(suggestion.locationIds),
                                            onSelect: {
                                                selectedLocations = Set(suggestion.locationIds)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    
                    // All Locations Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("All Locations")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !selectedLocations.isEmpty {
                                Button("Clear Selection") {
                                    selectedLocations.removeAll()
                                }
                                .font(.caption)
                                .foregroundColor(.spotifyGreen)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(availableLocations, id: \.id) { location in
                                    SelectableLocationRow(
                                        location: location,
                                        isSelected: selectedLocations.contains(location.id),
                                        tripAssignments: tripManager.getTripsContainingLocation(location.id),
                                        onToggle: {
                                            if selectedLocations.contains(location.id) {
                                                selectedLocations.remove(location.id)
                                            } else {
                                                selectedLocations.insert(location.id)
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
        .onAppear {
            tripSuggestions = tripManager.suggestTripsFromLocations(availableLocations)
        }
        .sheet(isPresented: $showingCreateTripSheet) {
            CreateTripFromLocationsSheet(
                selectedLocationIds: Array(selectedLocations),
                locations: availableLocations,
                onCreateTrip: { name, description, color in
                    let _ = tripManager.createTripFromLocations(
                        name: name,
                        locationIds: Array(selectedLocations),
                        locations: availableLocations,
                        description: description,
                        color: color
                    )
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Selectable Location Row
struct SelectableLocationRow: View {
    let location: LocationData
    let isSelected: Bool
    let tripAssignments: [Trip]
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Selection indicator
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
                
                // Location info
                VStack(alignment: .leading, spacing: 6) {
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(location.timestamp, style: .date)
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
                        
                        // Show existing trip assignments
                        if !tripAssignments.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text("In \(tripAssignments.count) trip\(tripAssignments.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
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

// MARK: - Trip Suggestion Card
struct TripSuggestionCard: View {
    let suggestion: TripSuggestion
    let locations: [LocationData]
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var suggestionLocations: [LocationData] {
        locations.filter { suggestion.locationIds.contains($0.id) }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Header
                VStack(spacing: 6) {
                    Text(suggestion.suggestedName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(suggestion.typeDescription)
                        .font(.caption)
                        .foregroundColor(.spotifyGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.spotifyGreen.opacity(0.2))
                        )
                }
                
                // Quick stats
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        Text("\(suggestion.locationIds.count) locations")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                        
                        Spacer()
                        
                        Text(suggestion.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                    }
                    
                    if !suggestionLocations.isEmpty {
                        let totalPhotos = suggestionLocations.reduce(0) { $0 + $1.photoIdentifiers.count }
                        if totalPhotos > 0 {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                                
                                Text("\(totalPhotos) photos")
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.spotifyGreen.opacity(0.2) : Color.spotifyMediumGray.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.spotifyGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Trip from Locations Sheet
struct CreateTripFromLocationsSheet: View {
    let selectedLocationIds: [UUID]
    let locations: [LocationData]
    let onCreateTrip: (String, String?, Trip.TripColor) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var selectedColor: Trip.TripColor = .green
    @FocusState private var isNameFieldFocused: Bool
    
    private var selectedLocations: [LocationData] {
        locations.filter { selectedLocationIds.contains($0.id) }
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
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Create Trip")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("From \(selectedLocationIds.count) selected locations")
                            .font(.subheadline)
                            .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.top, 20)
                    
                    // Preview selected locations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Locations")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedLocations.prefix(5).enumerated()), id: \.element.id) { index, location in
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.spotifyGreen)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text("\(index + 1)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(location.address.components(separatedBy: ",").first ?? location.address)
                                            .font(.caption2)
                                            .foregroundColor(.spotifyTextGray)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 80)
                                    }
                                }
                                
                                if selectedLocations.count > 5 {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.spotifyTextGray.opacity(0.6))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text("+\(selectedLocations.count - 5)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text("more")
                                            .font(.caption2)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
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
                        
                        // Trip Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            TextField("What was this trip about?", text: $tripDescription, axis: .vertical)
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
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(color.color)
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                                )
                                            
                                            Text(color.displayName)
                                                .font(.caption2)
                                                .foregroundColor(selectedColor == color ? .white : .spotifyTextGray)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Create Button
                    Button(action: {
                        let finalDescription = tripDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCreateTrip(
                            tripName,
                            finalDescription.isEmpty ? nil : finalDescription,
                            selectedColor
                        )
                    }) {
                        Text("Create Trip")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(selectedColor.color)
                            )
                    }
                    .disabled(tripName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(tripName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                // Generate smart trip name based on selected locations
                generateSmartTripName()
                isNameFieldFocused = true
            }
        }
    }
    
    private func generateSmartTripName() {
        guard !selectedLocations.isEmpty else { return }
        
        // Extract cities from addresses
        let cities = selectedLocations.compactMap { location in
            let components = location.address.components(separatedBy: ",")
            if components.count >= 2 {
                return components[1].trimmingCharacters(in: .whitespaces)
            }
            return nil
        }
        
        let uniqueCities = Array(Set(cities))
        
        if uniqueCities.count == 1, let city = uniqueCities.first {
            tripName = "\(city) Adventure"
        } else if uniqueCities.count > 1 {
            tripName = "Multi-City Trip"
        } else {
            tripName = "My Trip"
        }
    }
}

#Preview {
    TripSuggestionsView(
        tripManager: TripManager(),
        dataManager: DataManager()
    )
    .preferredColorScheme(.dark)
}
