// /Views/Components/TripComponents.swift

import SwiftUI
import CoreLocation

// MARK: - Active Trip Banner
struct ActiveTripBanner: View {
    let trip: Trip
    let locationCount: Int
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
                        
                        // Active indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(trip.color.color)
                                .frame(width: 8, height: 8)
                            
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(trip.color.color)
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
                    }
                }
                
                // End Trip Button
                Button(action: onEnd) {
                    Image(systemName: "stop.circle")
                        .font(.title2)
                        .foregroundColor(.spotifyTextGray)
                }
                .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.spotifyMediumGray.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(trip.color.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: Trip
    let statistics: TripStatistics
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

// MARK: - Start Trip Sheet
struct StartTripSheet: View {
    let onStartTrip: (String, String?, Trip.TripColor) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var selectedColor: Trip.TripColor = .green
    @State private var showDescription = false
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
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            let finalDescription = tripDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                            onStartTrip(
                                tripName,
                                finalDescription.isEmpty ? nil : finalDescription,
                                selectedColor
                            )
                            dismiss()
                        }) {
                            Text("Start Trip")
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
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }
}

// MARK: - Trip Location Assignment Sheet
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

// MARK: - Trip Selection Row
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
    
    // Create sample locations for the trip
    let sampleLocations = [
        LocationData(
            address: "Apple Park, Cupertino, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            altitude: 56.7,
            comment: "Amazing place!",
            photoIdentifiers: ["photo1", "photo2"]
        ),
        LocationData(
            address: "Golden Gate Bridge, San Francisco, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
            altitude: 67.2,
            photoIdentifiers: ["photo3", "photo4", "photo5"]
        ),
        LocationData(
            address: "Pier 39, San Francisco, CA",
            coordinate: CLLocationCoordinate2D(latitude: 37.8086, longitude: -122.4098),
            altitude: 3.1,
            comment: "Great seafood!",
            photoIdentifiers: ["photo6"]
        )
    ]
    
    // Use proper TripStatistics initializer
    let sampleStats = TripStatistics(trip: sampleTrip, locations: sampleLocations)
    
    TripCard(
        trip: sampleTrip,
        statistics: sampleStats,
        onTap: {}
    )
    .preferredColorScheme(.dark)
    .padding()
}
