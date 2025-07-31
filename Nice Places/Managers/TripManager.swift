// /Managers/TripManager.swift

import Foundation
import SwiftUI
import CoreLocation

@Observable
class TripManager {
    private let userDefaults = UserDefaults.standard
    private let savedTripsKey = "SavedTrips"
    
    var savedTrips: [Trip] = []
    var activeTrip: Trip? {
        return savedTrips.first { $0.isActive }
    }
    
    init() {
        loadSavedTrips()
    }
    
    // MARK: - Trip Management
    func startNewTrip(name: String, description: String? = nil, color: Trip.TripColor = .green) -> Trip {
        // End any existing active trip
        endActiveTrip()
        
        let newTrip = Trip(name: name, description: description, color: color)
        savedTrips.append(newTrip)
        saveToPersistence()
        
        return newTrip
    }
    
    func endActiveTrip() {
        if let activeIndex = savedTrips.firstIndex(where: { $0.isActive }) {
            savedTrips[activeIndex].endTrip()
            saveToPersistence()
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        savedTrips.removeAll { $0.id == trip.id }
        saveToPersistence()
    }
    
    func updateTrip(_ updatedTrip: Trip) {
        if let index = savedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
            savedTrips[index] = updatedTrip
            saveToPersistence()
        }
    }
    
    // MARK: - Location Assignment
    func addLocationToActiveTrip(_ locationId: UUID) {
        guard let activeIndex = savedTrips.firstIndex(where: { $0.isActive }) else { return }
        
        savedTrips[activeIndex].addLocation(locationId)
        saveToPersistence()
    }
    
    func addLocationToTrip(_ locationId: UUID, tripId: UUID) {
        guard let tripIndex = savedTrips.firstIndex(where: { $0.id == tripId }) else { return }
        
        savedTrips[tripIndex].addLocation(locationId)
        saveToPersistence()
    }
    
    func removeLocationFromTrip(_ locationId: UUID, tripId: UUID) {
        guard let tripIndex = savedTrips.firstIndex(where: { $0.id == tripId }) else { return }
        
        savedTrips[tripIndex].removeLocation(locationId)
        saveToPersistence()
    }
    
    // MARK: - Trip Creation from Existing Locations
    func createTripFromLocations(name: String, locationIds: [UUID], locations: [LocationData], description: String? = nil, color: Trip.TripColor = .green) -> Trip {
        // Find the date range from the selected locations
        let tripLocations = locations.filter { locationIds.contains($0.id) }
        guard !tripLocations.isEmpty else {
            return Trip(name: name, description: description, color: color)
        }
        
        let startDate = tripLocations.map { $0.timestamp }.min() ?? Date()
        let endDate = tripLocations.map { $0.timestamp }.max() ?? Date()
        
        let newTrip = Trip(
            name: name,
            locationIds: locationIds,
            startDate: startDate,
            endDate: endDate,
            description: description,
            color: color
        )
        
        savedTrips.append(newTrip)
        saveToPersistence()
        
        return newTrip
    }
    
    // MARK: - Trip Queries
    func getTripsContainingLocation(_ locationId: UUID) -> [Trip] {
        return savedTrips.filter { $0.locationIds.contains(locationId) }
    }
    
    func getLocationsForTrip(_ trip: Trip, from allLocations: [LocationData]) -> [LocationData] {
        return allLocations.filter { trip.locationIds.contains($0.id) }
            .sorted { $0.timestamp < $1.timestamp } // Sort chronologically
    }
    
    func getTripStatistics(_ trip: Trip, from allLocations: [LocationData]) -> TripStatistics {
        return TripStatistics(trip: trip, locations: allLocations)
    }
    
    // MARK: - Smart Trip Suggestions
    func suggestTripsFromLocations(_ locations: [LocationData]) -> [TripSuggestion] {
        var suggestions: [TripSuggestion] = []
        
        // Group locations by date (same day trips)
        let groupedByDate = Dictionary(grouping: locations) { location in
            Calendar.current.startOfDay(for: location.timestamp)
        }
        
        for (date, dayLocations) in groupedByDate {
            if dayLocations.count >= 2 { // At least 2 locations to make a trip
                let suggestion = TripSuggestion(
                    suggestedName: generateTripName(for: dayLocations, date: date),
                    locationIds: dayLocations.map { $0.id },
                    date: date,
                    type: .dayTrip
                )
                suggestions.append(suggestion)
            }
        }
        
        // Group by proximity (locations within 5km of each other)
        suggestions.append(contentsOf: suggestProximityTrips(from: locations))
        
        return suggestions.sorted { $0.date > $1.date }
    }
    
    private func generateTripName(for locations: [LocationData], date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Try to extract city/area name from addresses
        let cityNames = locations.compactMap { location in
            location.address.components(separatedBy: ",").dropFirst().first?.trimmingCharacters(in: .whitespaces)
        }
        
        let uniqueCities = Array(Set(cityNames))
        
        if uniqueCities.count == 1, let city = uniqueCities.first {
            return "\(city) Trip"
        } else if uniqueCities.count > 1 {
            return "Multi-City Adventure"
        } else {
            return "Trip on \(formatter.string(from: date))"
        }
    }
    
    private func suggestProximityTrips(from locations: [LocationData]) -> [TripSuggestion] {
        // Implementation for proximity-based trip suggestions
        // This is a simplified version - could be enhanced with clustering algorithms
        return []
    }
    
    // MARK: - Persistence
    private func saveToPersistence() {
        if let encoded = try? JSONEncoder().encode(savedTrips) {
            userDefaults.set(encoded, forKey: savedTripsKey)
        }
    }
    
    private func loadSavedTrips() {
        if let data = userDefaults.data(forKey: savedTripsKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            savedTrips = decoded
        }
    }
    
    // MARK: - Utility
    func getTripCount() -> Int {
        return savedTrips.count
    }
    
    func getActiveTripsCount() -> Int {
        return savedTrips.filter { $0.isActive }.count
    }
    
    func getCompletedTripsCount() -> Int {
        return savedTrips.filter { !$0.isActive }.count
    }
}

// MARK: - Trip Suggestion Helper
struct TripSuggestion: Identifiable {
    let id = UUID()
    let suggestedName: String
    let locationIds: [UUID]
    let date: Date
    let type: SuggestionType
    
    enum SuggestionType {
        case dayTrip
        case proximityTrip
        case weekendTrip
    }
    
    var typeDescription: String {
        switch type {
        case .dayTrip: return "Same Day"
        case .proximityTrip: return "Nearby Places"
        case .weekendTrip: return "Weekend"
        }
    }
}
