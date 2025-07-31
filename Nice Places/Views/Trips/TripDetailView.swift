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
    @State private var selectedLocation: LocationData? // NEW: For location detail view
    @State private var photoManager = PhotoManager()
    
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
                            // View on Map
                            if !tripLocations.isEmpty {
                                Button(action: { showingMapView = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "map.fill")
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("View Trip on Map")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                            
                                            Text("See all locations from this trip")
                                                .font(.caption)
                                                .opacity(0.8)
                                        }
                                        
                                        Spacer()
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
                                Text("Trip Locations")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(tripLocations.enumerated()), id: \.element.id) { index, location in
                                        TripLocationRow(
                                            location: location,
                                            index: index + 1,
                                            tripColor: trip.color.color,
                                            photoManager: photoManager,
                                            onTap: {
                                                selectedLocation = location // NEW: Set selected location
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
            AllLocationsMapView(
                locations: tripLocations,
                onDismiss: { showingMapView = false },
                onLocationSelected: { location in
                    // Could show location detail here
                    showingMapView = false
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
            // NEW: Location detail view
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
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - Trip Location Row
struct TripLocationRow: View {
    let location: LocationData
    let index: Int
    let tripColor: Color
    let photoManager: PhotoManager
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) { // NEW: Make entire row tappable
            HStack(spacing: 16) {
                // Step indicator
                ZStack {
                    Circle()
                        .fill(tripColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(tripColor)
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
        .buttonStyle(.plain) // NEW: Use plain button style
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.spotifyMediumGray.opacity(0.4))
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

// MARK: - Edit Trip Sheet
struct EditTripSheet: View {
    let trip: Trip
    let onUpdate: (Trip) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String
    @State private var tripDescription: String
    @State private var selectedColor: Trip.TripColor
    @FocusState private var isNameFieldFocused: Bool
    
    init(trip: Trip, onUpdate: @escaping (Trip) -> Void) {
        self.trip = trip
        self.onUpdate = onUpdate
        self._tripName = State(initialValue: trip.name)
        self._tripDescription = State(initialValue: trip.tripDescription ?? "")
        self._selectedColor = State(initialValue: trip.color)
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
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            var updatedTrip = trip
                            updatedTrip.name = tripName
                            updatedTrip.tripDescription = tripDescription.isEmpty ? nil : tripDescription
                            updatedTrip.color = selectedColor
                            
                            onUpdate(updatedTrip)
                            dismiss()
                        }) {
                            Text("Update Trip")
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
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

#Preview {
    let sampleTrip = Trip(name: "Weekend Adventure", description: "Exploring the city", color: .green)
    
    TripDetailView(
        trip: sampleTrip,
        tripManager: TripManager(),
        dataManager: DataManager(),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
