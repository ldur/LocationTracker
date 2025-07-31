// /Models/LocationData.swift

import Foundation
import CoreLocation

struct LocationData: Identifiable, Codable, Hashable, Equatable {
    let id: UUID // Changed to let but will be set in initializers
    let address: String
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    let timestamp: Date
    let comment: String? // NEW: Optional comment
    let photoIdentifiers: [String] // NEW: Photo/video asset identifiers
    
    // Custom coding for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, address, altitude, timestamp, latitude, longitude, comment, photoIdentifiers // Added photoIdentifiers
    }
    
    init(address: String, coordinate: CLLocationCoordinate2D, altitude: Double, comment: String? = nil, photoIdentifiers: [String] = []) {
        self.id = UUID() // Generate new ID for new locations
        self.address = address
        self.coordinate = coordinate
        self.altitude = altitude
        self.timestamp = Date()
        self.comment = comment // NEW: Store comment
        self.photoIdentifiers = photoIdentifiers // NEW: Store photo IDs
    }
    
    // NEW: Initializer for updating existing location (preserves ID and timestamp)
    init(id: UUID, address: String, coordinate: CLLocationCoordinate2D, altitude: Double, timestamp: Date, comment: String?, photoIdentifiers: [String] = []) {
        self.id = id
        self.address = address
        self.coordinate = coordinate
        self.altitude = altitude
        self.timestamp = timestamp
        self.comment = comment
        self.photoIdentifiers = photoIdentifiers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id) // Decode the ID
        address = try container.decode(String.self, forKey: .address)
        altitude = try container.decode(Double.self, forKey: .altitude)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        comment = try container.decodeIfPresent(String.self, forKey: .comment) // NEW: Optional decoding
        photoIdentifiers = try container.decodeIfPresent([String].self, forKey: .photoIdentifiers) ?? [] // NEW: Photo IDs with default
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id) // Encode the ID
        try container.encode(address, forKey: .address)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(comment, forKey: .comment) // NEW: Optional encoding
        try container.encode(photoIdentifiers, forKey: .photoIdentifiers) // NEW: Encode photo IDs
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable Conformance
    static func == (lhs: LocationData, rhs: LocationData) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - CLLocationCoordinate2D Extensions for Hashable Support
extension CLLocationCoordinate2D: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
