// /Managers/DataManager.swift

import Foundation
import SwiftUI

@Observable
class DataManager {
    private let userDefaults = UserDefaults.standard
    private let savedLocationsKey = "SavedLocations"
    
    var savedLocations: [LocationData] = []
    
    init() {
        loadSavedLocations()
    }
    
    func saveLocation(_ locationData: LocationData) {
        savedLocations.append(locationData)
        saveToPersistence()
    }
    
    private func saveToPersistence() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            userDefaults.set(encoded, forKey: savedLocationsKey)
        }
    }
    
    private func loadSavedLocations() {
        if let data = userDefaults.data(forKey: savedLocationsKey),
           let decoded = try? JSONDecoder().decode([LocationData].self, from: data) {
            savedLocations = decoded
        }
    }
    
    func deleteLocation(at indexSet: IndexSet) {
        savedLocations.remove(atOffsets: indexSet)
        saveToPersistence()
    }
    
    // NEW: Update existing location
    func updateLocation(_ updatedLocation: LocationData) {
        if let index = savedLocations.firstIndex(where: { $0.id == updatedLocation.id }) {
            savedLocations[index] = updatedLocation
            saveToPersistence()
        }
    }
    
    func clearAllLocations() {
        savedLocations.removeAll()
        saveToPersistence()
    }
    
    func getLocationCount() -> Int {
        return savedLocations.count
    }
}
