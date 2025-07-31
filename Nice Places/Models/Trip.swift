// /Models/Trip.swift

import Foundation
import CoreLocation
import SwiftUI

struct Trip: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var locationIds: [UUID] // References to LocationData IDs
    var coverPhotoIdentifier: String? // Optional cover photo
    var tripDescription: String?
    var color: TripColor // Visual identifier
    
    // Trip categories
    enum TripColor: String, CaseIterable, Codable {
        case green = "spotifyGreen"
        case blue = "systemBlue"
        case purple = "systemPurple"
        case orange = "systemOrange"
        case red = "systemRed"
        case yellow = "systemYellow"
        case pink = "systemPink"
        case indigo = "systemIndigo"
        
        var color: Color {
            switch self {
            case .green: return .spotifyGreen
            case .blue: return .blue
            case .purple: return .purple
            case .orange: return .orange
            case .red: return .red
            case .yellow: return .yellow
            case .pink: return .pink
            case .indigo: return .indigo
            }
        }
        
        var displayName: String {
            switch self {
            case .green: return "Adventure"
            case .blue: return "Business"
            case .purple: return "Vacation"
            case .orange: return "Food & Dining"
            case .red: return "Emergency"
            case .yellow: return "Exploration"
            case .pink: return "Romance"
            case .indigo: return "Nature"
            }
        }
    }
    
    init(name: String, description: String? = nil, color: TripColor = .green) {
        self.id = UUID()
        self.name = name
        self.startDate = Date()
        self.endDate = nil
        self.isActive = true
        self.locationIds = []
        self.coverPhotoIdentifier = nil
        self.tripDescription = description
        self.color = color
    }
    
    // Initialize with existing data for retrospective trips
    init(name: String, locationIds: [UUID], startDate: Date, endDate: Date? = nil, description: String? = nil, color: TripColor = .green) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = false
        self.locationIds = locationIds
        self.coverPhotoIdentifier = nil
        self.tripDescription = description
        self.color = color
    }
    
    // MARK: - Computed Properties
    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
    
    var durationDescription: String {
        let end = endDate ?? Date()
        let interval = end.timeIntervalSince(startDate)
        
        if interval < 3600 { // Less than 1 hour
            let minutes = Int(interval / 60)
            return "\(minutes) min"
        } else if interval < 86400 { // Less than 1 day
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else { // 1 day or more
            let days = Int(interval / 86400)
            let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
    }
    
    var status: String {
        isActive ? "Active" : "Completed"
    }
    
    var statusIcon: String {
        isActive ? "location.fill" : "checkmark.circle.fill"
    }
    
    // MARK: - Trip Actions
    mutating func endTrip() {
        isActive = false
        endDate = Date()
    }
    
    mutating func addLocation(_ locationId: UUID) {
        if !locationIds.contains(locationId) {
            locationIds.append(locationId)
        }
    }
    
    mutating func removeLocation(_ locationId: UUID) {
        locationIds.removeAll { $0 == locationId }
    }
    
    mutating func updateCoverPhoto(_ photoIdentifier: String?) {
        coverPhotoIdentifier = photoIdentifier
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Trip Statistics Helper
struct TripStatistics {
    let totalLocations: Int
    let totalPhotos: Int
    let averageAltitude: Double
    let distanceCovered: Double
    let locationSpread: CLLocationDistance
    
    init(trip: Trip, locations: [LocationData]) {
        let tripLocations = locations.filter { trip.locationIds.contains($0.id) }
        
        self.totalLocations = tripLocations.count
        self.totalPhotos = tripLocations.reduce(0) { $0 + $1.photoIdentifiers.count }
        
        let validAltitudes = tripLocations.compactMap { location in
            location.altitude.isFinite && !location.altitude.isNaN ? location.altitude : nil
        }
        self.averageAltitude = validAltitudes.isEmpty ? 0 : validAltitudes.reduce(0, +) / Double(validAltitudes.count)
        
        // Calculate total distance covered (rough estimation)
        var totalDistance: Double = 0
        if tripLocations.count > 1 {
            for i in 0..<(tripLocations.count - 1) {
                let from = CLLocation(latitude: tripLocations[i].coordinate.latitude, longitude: tripLocations[i].coordinate.longitude)
                let to = CLLocation(latitude: tripLocations[i + 1].coordinate.latitude, longitude: tripLocations[i + 1].coordinate.longitude)
                totalDistance += from.distance(from: to)
            }
        }
        self.distanceCovered = totalDistance
        
        // Calculate location spread (max distance between any two points)
        var maxDistance: Double = 0
        if tripLocations.count > 1 {
            for i in 0..<tripLocations.count {
                for j in (i + 1)..<tripLocations.count {
                    let from = CLLocation(latitude: tripLocations[i].coordinate.latitude, longitude: tripLocations[i].coordinate.longitude)
                    let to = CLLocation(latitude: tripLocations[j].coordinate.latitude, longitude: tripLocations[j].coordinate.longitude)
                    let distance = from.distance(from: to)
                    maxDistance = max(maxDistance, distance)
                }
            }
        }
        self.locationSpread = maxDistance
    }
}
