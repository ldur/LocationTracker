// /Managers/LocationManager.swift

import Foundation
import CoreLocation
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    var currentLocation: CLLocation?
    var currentAddress: String = "Finding your location..."
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isUpdatingLocation: Bool = false
    var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled."
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location access not authorized."
            return
        }
        
        isUpdatingLocation = true
        manager.startUpdatingLocation()
    }
    
    private func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        isUpdatingLocation = false
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Validate location data before using it
        guard location.coordinate.latitude.isFinite && location.coordinate.longitude.isFinite else {
            errorMessage = "Invalid location data received"
            return
        }
        
        currentLocation = location
        
        Task {
            await reverseGeocode(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        isUpdatingLocation = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            errorMessage = "Location access denied."
            stopLocationUpdates()
        default:
            break
        }
    }
    
    // MARK: - Reverse Geocoding
    @MainActor
    private func reverseGeocode(location: CLLocation) async {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                currentAddress = formatAddress(from: placemark)
            }
        } catch {
            currentAddress = "Address unavailable"
            errorMessage = "Geocoding error: \(error.localizedDescription)"
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }
        if let streetName = placemark.thoroughfare {
            components.append(streetName)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.isEmpty ? "Unknown Address" : components.joined(separator: ", ")
    }
}
