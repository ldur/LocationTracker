// /Views/Trips/TripsView.swift

import SwiftUI
import CoreLocation

struct TripsView: View {
    @Bindable var tripManager: TripManager
    @Bindable var dataManager: DataManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingStartTripSheet = false
    @State private var showingTripSuggestions = false
    @State private var selectedTrip: Trip?
    
    var completedTrips: [Trip] {
        tripManager.savedTrips.filter { !$0.isActive }.sorted { $0.startDate > $1.startDate }
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
                    // Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.spotifyMediumGray))
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("Your Trips")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(tripManager.getTripCount()) trips")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button(action: { showingStartTripSheet = true }) {
                                Label("Start New Trip", systemImage: "plus")
                            }
                            
                            if !dataManager.savedLocations.isEmpty {
                                Button(action: { showingTripSuggestions = true }) {
                                    Label("Trip Suggestions", systemImage: "sparkles")
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.spotifyGreen)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Active Trip Section
                            if let activeTrip = tripManager.activeTrip {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Active Trip")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button("End Trip") {
                                            tripManager.endActiveTrip()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyGreen)
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    ActiveTripBanner(
                                        trip: activeTrip,
                                        locationCount: activeTrip.locationIds.count,
                                        onTap: {
                                            selectedTrip = activeTrip
                                        },
                                        onEnd: {
                                            tripManager.endActiveTrip()
                                        }
                                    )
                                }
                            }
                            
                            // Quick Actions (when no active trip)
                            if tripManager.activeTrip == nil {
                                VStack(spacing: 16) {
                                    Text("Quick Actions")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 24)
                                    
                                    VStack(spacing: 12) {
                                        // Start New Trip
                                        Button(action: { showingStartTripSheet = true }) {
                                            HStack(spacing: 16) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.black)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Start New Trip")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.black)
                                                    
                                                    Text("Begin tracking your journey")
                                                        .font(.caption)
                                                        .foregroundColor(.black.opacity(0.7))
                                                }
                                                
                                                Spacer()
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.spotifyGreen)
                                            )
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        // Trip Suggestions (if locations exist)
                                        if !dataManager.savedLocations.isEmpty {
                                            Button(action: { showingTripSuggestions = true }) {
                                                HStack(spacing: 16) {
                                                    Image(systemName: "sparkles")
                                                        .font(.title2)
                                                        .foregroundColor(.spotifyGreen)
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("Create from Saved Locations")
                                                            .font(.headline)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.white)
                                                        
                                                        Text("Turn your locations into trips")
                                                            .font(.caption)
                                                            .foregroundColor(.spotifyTextGray)
                                                    }
                                                    
                                                    Spacer()
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(20)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.spotifyMediumGray.opacity(0.6))
                                                )
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                }
                            }
                            
                            // Completed Trips Section
                            if !completedTrips.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Past Trips")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 24)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(completedTrips, id: \.id) { trip in
                                            TripCard(
                                                trip: trip,
                                                statistics: tripManager.getTripStatistics(trip, from: dataManager.savedLocations),
                                                onTap: {
                                                    selectedTrip = trip
                                                }
                                            )
                                            .padding(.horizontal, 24)
                                            .contextMenu {
                                                Button(action: {
                                                    selectedTrip = trip
                                                }) {
                                                    Label("View Trip", systemImage: "eye")
                                                }
                                                
                                                Button(role: .destructive, action: {
                                                    tripManager.deleteTrip(trip)
                                                }) {
                                                    Label("Delete Trip", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            } else if tripManager.activeTrip == nil {
                                // Empty state
                                VStack(spacing: 16) {
                                    Spacer()
                                    
                                    Image(systemName: "map.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.spotifyTextGray)
                                    
                                    Text("No Trips Yet")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Start your first trip to begin tracking your adventures")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyTextGray)
                                        .multilineTextAlignment(.center)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 40)
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
            }
        }
        // FIXED: Updated StartTripSheet to include AutoSaveConfiguration parameter
        .sheet(isPresented: $showingStartTripSheet) {
            StartTripSheet { name, description, color, autoSaveConfig in
                let _ = tripManager.startNewTrip(
                    name: name,
                    description: description,
                    color: color,
                    autoSaveConfig: autoSaveConfig
                )
            }
        }
        .sheet(isPresented: $showingTripSuggestions) {
            TripSuggestionsView(
                tripManager: tripManager,
                dataManager: dataManager
            )
        }
        .fullScreenCover(item: $selectedTrip) { trip in
            TripDetailView(
                trip: trip,
                tripManager: tripManager,
                dataManager: dataManager,
                onDismiss: { selectedTrip = nil }
            )
        }
    }
}

#Preview {
    TripsView(
        tripManager: TripManager(),
        dataManager: DataManager()
    )
    .preferredColorScheme(.dark)
}
