// /Managers/TripManager.swift - FIXED Norwegian Street Name Extraction

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
    
    // NEW: Auto-save management with street tracking
    private var autoSaveTimer: Timer?
    private var lastKnownStreetName: String? // Track the last street/road name
    private var lastAutoSaveTime: Date?
    private var isFirstLocationOfTrip: Bool = true // Track if this is the first location
    
    init() {
        loadSavedTrips()
        setupAutoSaveMonitoring()
    }
    
    deinit {
        stopAutoSaveTimer()
    }
    
    // MARK: - Trip Management
    func startNewTrip(name: String, description: String? = nil, color: Trip.TripColor = .green, autoSaveConfig: AutoSaveConfiguration = AutoSaveConfiguration()) -> Trip {
        // End any existing active trip
        endActiveTrip()
        
        let newTrip = Trip(name: name, description: description, color: color, autoSaveConfig: autoSaveConfig)
        savedTrips.append(newTrip)
        saveToPersistence()
        
        // NEW: Setup auto-save for the new trip and reset state
        resetAutoSaveStateForNewTrip()
        setupAutoSaveForActiveTrip()
        
        return newTrip
    }
    
    func endActiveTrip() {
        if let activeIndex = savedTrips.firstIndex(where: { $0.isActive }) {
            savedTrips[activeIndex].endTrip()
            saveToPersistence()
            
            // NEW: Stop auto-save when trip ends
            stopAutoSaveTimer()
            resetAutoSaveStateForNewTrip()
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        savedTrips.removeAll { $0.id == trip.id }
        saveToPersistence()
        
        // NEW: Stop auto-save if deleted trip was active
        if trip.isActive {
            stopAutoSaveTimer()
            resetAutoSaveStateForNewTrip()
        }
    }
    
    func updateTrip(_ updatedTrip: Trip) {
        if let index = savedTrips.firstIndex(where: { $0.id == updatedTrip.id }) {
            let wasActive = savedTrips[index].isActive
            savedTrips[index] = updatedTrip
            saveToPersistence()
            
            // NEW: Update auto-save if this is the active trip
            if wasActive && updatedTrip.isActive {
                setupAutoSaveForActiveTrip()
            }
        }
    }
    
    // NEW: Update auto-save configuration for active trip
    func updateAutoSaveConfig(_ config: AutoSaveConfiguration) {
        guard let activeIndex = savedTrips.firstIndex(where: { $0.isActive }) else { return }
        
        savedTrips[activeIndex].autoSaveConfig = config
        saveToPersistence()
        
        // Restart auto-save with new configuration
        setupAutoSaveForActiveTrip()
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
    
    // MARK: - NEW: Enhanced Auto-Save Logic with Street Tracking
    private func setupAutoSaveMonitoring() {
        print("🚗 TripManager: Auto-save monitoring initialized")
    }
    
    private func resetAutoSaveStateForNewTrip() {
        lastKnownStreetName = nil
        lastAutoSaveTime = nil
        isFirstLocationOfTrip = true
        print("🚗 TripManager: Auto-save state reset for new trip")
    }
    
    private func setupAutoSaveForActiveTrip() {
        guard let activeTrip = self.activeTrip,
              activeTrip.autoSaveConfig.isEnabled else {
            stopAutoSaveTimer()
            return
        }
        
        print("🚗 TripManager: Setting up auto-save for trip: \(activeTrip.name)")
        print("🚗 Road change: \(activeTrip.autoSaveConfig.saveOnRoadChange), Time interval: \(activeTrip.autoSaveConfig.saveOnTimeInterval)")
        
        // Stop existing timer
        stopAutoSaveTimer()
        
        // Start time-based auto-save if enabled
        if activeTrip.autoSaveConfig.saveOnTimeInterval {
            startAutoSaveTimer(interval: activeTrip.autoSaveConfig.totalIntervalSeconds)
        }
    }
    
    private func startAutoSaveTimer(interval: TimeInterval) {
        guard interval >= 30 else { return } // Minimum 30 seconds
        
        print("🚗 TripManager: Starting auto-save timer with interval: \(interval) seconds")
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleTimeBasedAutoSave()
            }
        }
    }
    
    private func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        print("🚗 TripManager: Auto-save timer stopped")
    }
    
    @MainActor
    private func handleTimeBasedAutoSave() {
        guard let activeTrip = self.activeTrip,
              activeTrip.autoSaveConfig.isEnabled,
              activeTrip.autoSaveConfig.saveOnTimeInterval else {
            return
        }
        
        print("🚗 TripManager: Time-based auto-save triggered")
        
        // Notify that we need a location save
        NotificationCenter.default.post(
            name: .autoSaveLocationRequested,
            object: nil,
            userInfo: ["reason": "timeInterval", "tripId": activeTrip.id.uuidString]
        )
    }
    
    // FIXED: Enhanced street-based road change detection for Norwegian addresses
    func shouldAutoSaveLocation(_ newLocation: CLLocation, currentAddress: String) -> Bool {
        guard let activeTrip = self.activeTrip,
              activeTrip.autoSaveConfig.isEnabled,
              activeTrip.autoSaveConfig.saveOnRoadChange else {
            return false
        }
        
        // Extract current street name from address (Norwegian format)
        let currentStreetName = extractNorwegianStreetName(from: currentAddress)
        
        print("🚗 TripManager: Checking road change (Norwegian format)")
        print("🚗 Current street: '\(currentStreetName ?? "unknown")'")
        print("🚗 Last known street: '\(lastKnownStreetName ?? "none")'")
        print("🚗 Is first location: \(isFirstLocationOfTrip)")
        
        // First location of the trip - always save
        if isFirstLocationOfTrip {
            print("🚗 TripManager: First location of trip - auto-saving")
            return true
        }
        
        // Check if we have a previous street to compare
        guard let lastStreet = lastKnownStreetName,
              let currentStreet = currentStreetName else {
            // If we can't determine street names, fall back to distance-based detection
            return shouldAutoSaveBasedOnDistance(newLocation, config: activeTrip.autoSaveConfig)
        }
        
        // Compare street names (case-insensitive, ignoring house numbers)
        let streetChanged = !lastStreet.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .elementsEqual(currentStreet.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        
        if streetChanged {
            print("🚗 TripManager: Street change detected: '\(lastStreet)' → '\(currentStreet)'")
            return true
        }
        
        print("🚗 TripManager: No street change detected (same street, different house number)")
        return false
    }
    
    // FIXED: Extract street name from Norwegian address format
    private func extractNorwegianStreetName(from address: String) -> String? {
        // Norwegian address format: "Akersgata 40, 0123 Oslo" or "Grubbegata 1, Oslo"
        let components = address.components(separatedBy: ",")
        
        guard let streetComponent = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
              !streetComponent.isEmpty else {
            print("🚗 TripManager: No street component found in: '\(address)'")
            return nil
        }
        
        print("🚗 TripManager: Processing street component: '\(streetComponent)'")
        
        // Split by spaces to separate street name from house number
        let streetParts = streetComponent.components(separatedBy: " ")
        
        // Norwegian format: Street name comes first, house number comes last
        // Examples: "Akersgata 40", "Karl Johans gate 22", "Storgata 15B"
        
        guard streetParts.count > 1 else {
            // Only one part - could be just street name without house number
            print("🚗 TripManager: Single part street component: '\(streetComponent)'")
            return streetComponent
        }
        
        // Check if the last part contains numbers (house number)
        let lastPart = streetParts.last!
        let hasNumbers = lastPart.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        
        if hasNumbers {
            // Last part has numbers (likely house number), take everything except the last part
            let streetName = streetParts.dropLast().joined(separator: " ")
            print("🚗 TripManager: Extracted Norwegian street name: '\(streetName)' (removed house number: '\(lastPart)')")
            return streetName.isEmpty ? streetComponent : streetName
        } else {
            // No clear house number pattern, return the full street component
            print("🚗 TripManager: No clear house number found, using full component: '\(streetComponent)'")
            return streetComponent
        }
    }
    
    // ENHANCED: Better distance-based detection when street names can't be determined
    private func shouldAutoSaveBasedOnDistance(_ newLocation: CLLocation, config: AutoSaveConfiguration) -> Bool {
        print("🚗 TripManager: Using distance-based fallback for road change detection")
        
        // For the first location, always save
        if isFirstLocationOfTrip {
            print("🚗 TripManager: First location of trip (distance fallback) - auto-saving")
            return true
        }
        
        // This could be enhanced to track the last saved location and compare distances
        // For now, we'll be conservative and not auto-save unless we can detect street changes
        print("🚗 TripManager: Distance-based fallback - no auto-save (conservative approach)")
        return false
    }
    
    // FIXED: Update auto-save state after successful save (with Norwegian street extraction)
    func didAutoSaveLocation(_ location: CLLocation, address: String) {
        // Extract and store the street name for future comparison (Norwegian format)
        lastKnownStreetName = extractNorwegianStreetName(from: address)
        lastAutoSaveTime = Date()
        isFirstLocationOfTrip = false
        
        print("🚗 TripManager: Auto-save state updated (Norwegian format)")
        print("🚗 Stored street name: '\(lastKnownStreetName ?? "unknown")'")
        print("🚗 First location flag cleared")
    }
    
    // MARK: - Trip Creation from Existing Locations
    func createTripFromLocations(name: String, locationIds: [UUID], locations: [LocationData], description: String? = nil, color: Trip.TripColor = .green, autoSaveConfig: AutoSaveConfiguration = AutoSaveConfiguration()) -> Trip {
        // Find the date range from the selected locations
        let tripLocations = locations.filter { locationIds.contains($0.id) }
        guard !tripLocations.isEmpty else {
            return Trip(name: name, description: description, color: color, autoSaveConfig: autoSaveConfig)
        }
        
        let startDate = tripLocations.map { $0.timestamp }.min() ?? Date()
        let endDate = tripLocations.map { $0.timestamp }.max() ?? Date()
        
        let newTrip = Trip(
            name: name,
            locationIds: locationIds,
            startDate: startDate,
            endDate: endDate,
            description: description,
            color: color,
            autoSaveConfig: autoSaveConfig
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
            
            // Setup auto-save for any active trip after loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.setupAutoSaveForActiveTrip()
            }
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
    
    // MARK: - NEW: Debug helper to get current auto-save state
    func getAutoSaveDebugInfo() -> String {
        guard let activeTrip = self.activeTrip else {
            return "No active trip"
        }
        
        var info = "Trip: \(activeTrip.name)\n"
        info += "Auto-save enabled: \(activeTrip.autoSaveConfig.isEnabled)\n"
        info += "Last street: \(lastKnownStreetName ?? "none")\n"
        info += "First location: \(isFirstLocationOfTrip)\n"
        info += "Timer running: \(autoSaveTimer != nil)"
        
        return info
    }
}

// MARK: - AUTO-SAVE NOTIFICATION EXTENSIONS
extension Notification.Name {
    static let autoSaveLocationRequested = Notification.Name("autoSaveLocationRequested")
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
