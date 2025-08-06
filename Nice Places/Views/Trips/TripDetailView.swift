// /Views/Trips/TripDetailView.swift

import SwiftUI
import CoreLocation

struct TripDetailView: View {
    let trip: Trip
    @Bindable var tripManager: TripManager
    @Bindable var dataManager: DataManager
    let onDismiss: () -> Void
    
    @State private var showingMapView = false
    @State private var showingEditSheet = false
    @State private var selectedLocation: LocationData?
    @State private var photoManager = PhotoManager()
    @State private var showingNavigationLauncher = false
    @State private var showingNavigation = false
    @State private var navigationStartIndex = 0

    
    private var tripLocations: [LocationData] {
        tripManager.getLocationsForTrip(trip, from: dataManager.savedLocations)
    }
    
    private var tripStatistics: TripStatistics {
        tripManager.getTripStatistics(trip, from: dataManager.savedLocations)
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Trip Icon and Name
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [trip.color.color, trip.color.color.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(String(trip.name.prefix(1)).uppercased())
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(spacing: 6) {
                                    Text(trip.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: trip.statusIcon)
                                            .font(.subheadline)
                                            .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                                        
                                        Text(trip.status)
                                            .font(.subheadline)
                                            .foregroundColor(trip.isActive ? trip.color.color : .spotifyTextGray)
                                        
                                        Text("•")
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(trip.color.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        // NEW: Enhanced auto-save indicator with trip type
                                        if trip.autoSaveConfig.isEnabled {
                                            Text("•")
                                                .foregroundColor(.spotifyTextGray)
                                            
                                            HStack(spacing: 2) {
                                                Image(systemName: trip.autoSaveConfig.tripType.icon)
                                                    .font(.subheadline)
                                                    .foregroundColor(.spotifyGreen)
                                                
                                                Text(trip.autoSaveConfig.tripType.displayName)
                                                    .font(.subheadline)
                                                    .foregroundColor(.spotifyGreen)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Trip Details Card
                            VStack(spacing: 16) {
                                // Duration and Dates
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Started")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(trip.startDate, style: .date)
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .center, spacing: 8) {
                                        Text("Duration")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(trip.durationDescription)
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 8) {
                                        Text(trip.isActive ? "Active" : "Ended")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(trip.endDate ?? Date(), style: trip.isActive ? .relative : .date)
                                            .font(.footnote)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Description
                                if let description = trip.tripDescription, !description.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Description")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.spotifyTextGray)
                                        
                                        Text(description)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                
                                // Enhanced Auto-save Configuration Display with Trip Type
                                if trip.autoSaveConfig.isEnabled {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Auto-Save Configuration")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.spotifyTextGray)
                                            
                                            Spacer()
                                            
                                            // Trip type badge
                                            HStack(spacing: 4) {
                                                Text(trip.autoSaveConfig.tripType.emoji)
                                                    .font(.caption)
                                                
                                                Text(trip.autoSaveConfig.tripType.displayName)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.spotifyGreen)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.spotifyGreen.opacity(0.2))
                                            )
                                        }
                                        
                                        HStack(spacing: 16) {
                                            if trip.autoSaveConfig.saveOnRoadChange {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "road.lanes")
                                                        .font(.caption)
                                                        .foregroundColor(.spotifyGreen)
                                                    Text("Road Change")
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            if trip.autoSaveConfig.saveOnTimeInterval {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "timer")
                                                        .font(.caption)
                                                        .foregroundColor(.spotifyGreen)
                                                    Text("\(Int(trip.autoSaveConfig.totalIntervalSeconds / 60))min")
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Statistics
                                VStack(spacing: 12) {
                                    Text("Trip Statistics")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.spotifyTextGray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 0) {
                                        StatisticView(
                                            title: "Locations",
                                            value: "\(tripStatistics.totalLocations)",
                                            icon: "location"
                                        )
                                        
                                        Rectangle()
                                            .fill(Color.spotifyTextGray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        StatisticView(
                                            title: "Photos",
                                            value: "\(tripStatistics.totalPhotos)",
                                            icon: "photo"
                                        )
                                        
                                        Rectangle()
                                            .fill(Color.spotifyTextGray.opacity(0.3))
                                            .frame(width: 1, height: 40)
                                        
                                        StatisticView(
                                            title: "Distance",
                                            value: formatDistance(tripStatistics.distanceCovered),
                                            icon: "point.topleft.down.curvedto.point.bottomright.up"
                                        )
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.spotifyMediumGray)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // View Trip Route Button (consistent with Save This Location styling)
                            if !tripLocations.isEmpty {
                                Button(action: { showingMapView = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "map.circle.fill")
                                            .font(.title2)
                                        
                                        Text("View Trip Route")
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
                                Button(action: { showingNavigationLauncher = true }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "location.north.circle.fill")
                                                .font(.title2)
                                            
                                            Text("Navigate Trip")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 28)
                                                .fill(Color.blue)
                                        )
                                    }
                                    .padding(.horizontal, 24)
                            }
                            
                            // Edit Trip
                            Button(action: { showingEditSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "pencil")
                                        .font(.title2)
                                    
                                    Text("Edit Trip")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.spotifyMediumGray)
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Locations in Trip
                        if !tripLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Trip Route")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Enhanced route path indicator with trip type
                                    HStack(spacing: 8) {
                                        if trip.autoSaveConfig.isEnabled && trip.autoSaveConfig.tripType != .custom {
                                            HStack(spacing: 4) {
                                                Image(systemName: trip.autoSaveConfig.tripType.icon)
                                                    .font(.caption)
                                                    .foregroundColor(trip.color.color)
                                                
                                                Text(trip.autoSaveConfig.tripType.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(trip.color.color)
                                            }
                                            
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                                .font(.caption)
                                                .foregroundColor(trip.color.color)
                                            
                                            Text("\(formatDistance(tripStatistics.distanceCovered))")
                                                .font(.caption)
                                                .foregroundColor(trip.color.color)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(tripLocations.enumerated()), id: \.element.id) { index, location in
                                        TripLocationRow(
                                            location: location,
                                            index: index + 1,
                                            tripColor: trip.color.color,
                                            photoManager: photoManager,
                                            isFirst: index == 0,
                                            isLast: index == tripLocations.count - 1,
                                            onTap: {
                                                selectedLocation = location
                                            },
                                            onRemove: {
                                                tripManager.removeLocationFromTrip(location.id, tripId: trip.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.spotifyTextGray)
                                
                                Text("No Locations Yet")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(trip.isActive ? "Start exploring to add locations to this trip" : "This trip doesn't have any locations")
                                    .font(.subheadline)
                                    .foregroundColor(.spotifyTextGray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !tripLocations.isEmpty {
                            Button(action: { showingMapView = true }) {
                                Label("View Route", systemImage: "map")
                            }
                        }
                        
                        if trip.isActive {
                            Button(action: {
                                tripManager.endActiveTrip()
                            }) {
                                Label("End Trip", systemImage: "stop.circle")
                            }
                        }
                        
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Trip", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            tripManager.deleteTrip(trip)
                            onDismiss()
                        }) {
                            Label("Delete Trip", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingMapView) {
            TripRouteMapView(
                trip: trip,
                locations: dataManager.savedLocations,
                onDismiss: { showingMapView = false },
                onLocationSelected: { location in
                    showingMapView = false
                    // Small delay to allow map to dismiss before showing detail
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedLocation = location
                    }
                }
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripSheet(
                trip: trip,
                onUpdate: { updatedTrip in
                    tripManager.updateTrip(updatedTrip)
                }
            )
        }
        .fullScreenCover(item: $selectedLocation) { location in
            NavigationStack {
                LocationDetailView(
                    dataManager: dataManager,
                    location: location
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            selectedLocation = nil
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNavigationLauncher) {
            NavigationLauncherSheet(
                trip: trip,
                locations: tripLocations,
                onStartNavigation: { startIndex in
                    navigationStartIndex = startIndex
                    showingNavigationLauncher = false
                    showingNavigation = true
                },
                onDismiss: {
                    showingNavigationLauncher = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingNavigation) {
            TripNavigationView(
                trip: trip,
                locations: tripLocations,
                startLocationIndex: navigationStartIndex,
                onDismiss: {
                    showingNavigation = false
                }
            )
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Enhanced Trip Location Row with Route Context
struct TripLocationRow: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let photoManager: PhotoManager
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Enhanced step indicator with route context
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(tripColor.opacity(0.2))
                            .frame(width: isFirst || isLast ? 36 : 32, height: isFirst || isLast ? 36 : 32)
                        
                        if isFirst {
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(tripColor)
                        } else if isLast {
                            Image(systemName: "stop.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(tripColor)
                        } else {
                            Text("\(index)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(tripColor)
                        }
                    }
                    
                    // Connection line to next location (except for last)
                    if !isLast {
                        Rectangle()
                            .fill(tripColor.opacity(0.4))
                            .frame(width: 2, height: 16)
                    }
                }
                
                // Location preview
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.spotifyLightGray)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "location.fill")
                                .font(.headline)
                                .foregroundColor(.spotifyGreen)
                        )
                }
                
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    // Add route context to address
                    HStack {
                        if isFirst {
                            Text("START")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(tripColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(tripColor.opacity(0.2))
                                )
                        } else if isLast {
                            Text("END")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(tripColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(tripColor.opacity(0.2))
                                )
                        } else {
                            Text("STOP \(index)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.spotifyTextGray)
                        }
                        
                        Spacer()
                    }
                    
                    Text(location.address)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(location.timestamp, style: .time)
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
                            .foregroundColor(tripColor)
                        }
                        
                        if let comment = location.comment, !comment.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            Image(systemName: "text.bubble")
                                .font(.caption2)
                                .foregroundColor(.spotifyGreen)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "minus.circle")
                        .font(.headline)
                        .foregroundColor(.spotifyTextGray.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.spotifyMediumGray.opacity(0.4))
                .overlay(
                    // Subtle border for route context
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tripColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            loadThumbnail()
        }
        .contextMenu {
            Button(action: onTap) {
                Label("View Location", systemImage: "eye")
            }
            
            Button(role: .destructive, action: onRemove) {
                Label("Remove from Trip", systemImage: "minus.circle")
            }
        }
    }
    
    private func loadThumbnail() {
        guard let firstPhotoId = location.photoIdentifiers.first else { return }
        
        Task {
            let image = await photoManager.loadThumbnail(for: firstPhotoId, size: CGSize(width: 50, height: 50))
            await MainActor.run {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - FIXED: Edit Trip Sheet - Preserves Trip Type
struct EditTripSheet: View {
    let trip: Trip
    let onUpdate: (Trip) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String
    @State private var tripDescription: String
    @State private var selectedColor: Trip.TripColor
    @State private var autoSaveConfig: AutoSaveConfiguration
    @State private var showAutoSaveConfig = false
    @FocusState private var isNameFieldFocused: Bool
    
    init(trip: Trip, onUpdate: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onUpdate = onUpdate
        self._tripName = State(initialValue: trip.name)
        self._tripDescription = State(initialValue: trip.tripDescription ?? "")
        self._selectedColor = State(initialValue: trip.color)
        self._autoSaveConfig = State(initialValue: trip.autoSaveConfig)
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.spotifyGreen)
                            
                            Text("Edit Trip")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // Trip Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trip Name")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                TextField("Trip name", text: $tripName)
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
                                Text("Description")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                TextField("Trip description (optional)", text: $tripDescription, axis: .vertical)
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
                                Text("Category")
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
                            
                            // Enhanced Auto-Save Configuration (only for active trips) - FIXED
                            if trip.isActive {
                                VStack(spacing: 16) {
                                    // Auto-Save Toggle
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Auto-Save Settings")
                                                .font(.headline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            
                                            Text("Automatically save locations during this trip")
                                                .font(.caption)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $autoSaveConfig.isEnabled)
                                            .tint(.spotifyGreen)
                                    }
                                    
                                    // Auto-Save Configuration (when enabled) - FIXED VERSION
                                    if autoSaveConfig.isEnabled {
                                        VStack(spacing: 16) {
                                            // Trip Type Selection with Presets
                                            VStack(spacing: 12) {
                                                HStack {
                                                    Text("Trip Type")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    // Current trip type indicator
                                                    HStack(spacing: 4) {
                                                        Image(systemName: autoSaveConfig.tripType.icon)
                                                            .font(.caption)
                                                            .foregroundColor(.spotifyGreen)
                                                        Text(autoSaveConfig.tripType.displayName)
                                                            .font(.caption)
                                                            .foregroundColor(.spotifyGreen)
                                                    }
                                                }
                                                
                                                HStack(spacing: 8) {
                                                    EnhancedPresetButton(title: "Walking", emoji: "🚶", preset: .walking, currentConfig: $autoSaveConfig)
                                                    EnhancedPresetButton(title: "Bicycle", emoji: "🚴", preset: .bicycle, currentConfig: $autoSaveConfig)
                                                    EnhancedPresetButton(title: "Car", emoji: "🚗", preset: .car, currentConfig: $autoSaveConfig)
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
                                                    
                                                    Toggle("", isOn: $autoSaveConfig.saveOnRoadChange)
                                                        .tint(.spotifyGreen)
                                                        // REMOVED: onChange that was setting tripType to .custom
                                                }
                                                
                                                if autoSaveConfig.saveOnRoadChange {
                                                    VStack(alignment: .leading, spacing: 8) {
                                                        Text("Minimum Distance: \(Int(autoSaveConfig.minimumDistanceMeters))m")
                                                            .font(.caption)
                                                            .foregroundColor(.spotifyTextGray)
                                                        
                                                        Slider(
                                                            value: $autoSaveConfig.minimumDistanceMeters,
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
                                                    
                                                    Toggle("", isOn: $autoSaveConfig.saveOnTimeInterval)
                                                        .tint(.spotifyGreen)
                                                        // REMOVED: onChange that was setting tripType to .custom
                                                }
                                                
                                                if autoSaveConfig.saveOnTimeInterval {
                                                    HStack(spacing: 16) {
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("Minutes")
                                                                .font(.caption)
                                                                .foregroundColor(.spotifyTextGray)
                                                            
                                                            Picker("Minutes", selection: $autoSaveConfig.timeIntervalMinutes) {
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
                                                            
                                                            Picker("Seconds", selection: $autoSaveConfig.timeIntervalSeconds) {
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
                                                    if !autoSaveConfig.isValidTimeInterval {
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
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.spotifyMediumGray.opacity(0.6))
                                )
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
                    Button("Update") {
                        var updatedTrip = trip
                        updatedTrip.name = tripName
                        updatedTrip.tripDescription = tripDescription.isEmpty ? nil : tripDescription
                        updatedTrip.color = selectedColor
                        updatedTrip.autoSaveConfig = autoSaveConfig
                        
                        onUpdate(updatedTrip)
                        dismiss()
                    }
                    .foregroundColor(tripName.trimmingCharacters(in: .whitespaces).isEmpty ? .spotifyTextGray : .spotifyGreen)
                    .disabled(tripName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
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
        onTap: {}
    )
    .preferredColorScheme(.dark)
    .padding()
}
