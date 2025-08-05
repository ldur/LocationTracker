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
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            Task {
                await startLocationUpdates()
            }
        @unknown default:
            break
        }
    }
    
    @MainActor
    private func startLocationUpdates() async {
        // Check location services on background queue to avoid main thread blocking
        let servicesEnabled = await Task.detached {
            CLLocationManager.locationServicesEnabled()
        }.value
        
        guard servicesEnabled else {
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
    
    @MainActor
    private func stopLocationUpdates() {
        manager.stopUpdatingLocation()
        isUpdatingLocation = false
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Validate location data before using it
        guard location.coordinate.latitude.isFinite && location.coordinate.longitude.isFinite else {
            Task { @MainActor in
                errorMessage = "Invalid location data received"
            }
            return
        }
        
        Task { @MainActor in
            currentLocation = location
            await reverseGeocode(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Location error: \(error.localizedDescription)"
            isUpdatingLocation = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                await startLocationUpdates()
            case .denied, .restricted:
                errorMessage = "Location access denied."
                stopLocationUpdates()
            default:
                break
            }
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
    
    // UPDATED: Format address according to Norwegian conventions
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        // NORWEGIAN FORMAT: Street name + house number (no comma between them)
        var streetComponent = ""
        
        if let streetName = placemark.thoroughfare {
            streetComponent = streetName
            
            // Add house number after street name (Norwegian style)
            if let streetNumber = placemark.subThoroughfare {
                streetComponent += " \(streetNumber)"
            }
        } else if let streetNumber = placemark.subThoroughfare {
            // Fallback: if we only have street number
            streetComponent = streetNumber
        }
        
        if !streetComponent.isEmpty {
            addressComponents.append(streetComponent)
        }
        
        // NORWEGIAN FORMAT: Postal code + city (space separated, no comma between them)
        var cityComponent = ""
        
        if let postalCode = placemark.postalCode,
           let city = placemark.locality {
            cityComponent = "\(postalCode) \(city)"
        } else if let city = placemark.locality {
            // Fallback: city only if no postal code
            cityComponent = city
        } else if let postalCode = placemark.postalCode {
            // Fallback: postal code only if no city
            cityComponent = postalCode
        }
        
        if !cityComponent.isEmpty {
            addressComponents.append(cityComponent)
        }
        
        // Join main components with comma and space
        let formattedAddress = addressComponents.joined(separator: ", ")
        
        // Fallback for edge cases
        if formattedAddress.isEmpty {
            var fallbackComponents: [String] = []
            
            if let streetNumber = placemark.subThoroughfare {
                fallbackComponents.append(streetNumber)
            }
            if let streetName = placemark.thoroughfare {
                fallbackComponents.append(streetName)
            }
            if let city = placemark.locality {
                fallbackComponents.append(city)
            }
            if let state = placemark.administrativeArea {
                fallbackComponents.append(state)
            }
            if let postalCode = placemark.postalCode {
                fallbackComponents.append(postalCode)
            }
            
            return fallbackComponents.isEmpty ? "Unknown Address" : fallbackComponents.joined(separator: ", ")
        }
        
        return formattedAddress
    }
    
    // MARK: - Public Utility Methods
    
    /// Safely check if location services are enabled without blocking main thread
    func checkLocationServicesEnabled() async -> Bool {
        return await Task.detached {
            CLLocationManager.locationServicesEnabled()
        }.value
    }
    
    /// Get location accuracy description
    var accuracyDescription: String {
        guard let location = currentLocation else { return "Unknown" }
        
        let accuracy = location.horizontalAccuracy
        if accuracy < 0 {
            return "Invalid"
        } else if accuracy < 5 {
            return "Excellent"
        } else if accuracy < 10 {
            return "Good"
        } else if accuracy < 50 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    /// Force refresh location
    func refreshLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocation()
            return
        }
        
        Task {
            await startLocationUpdates()
        }
    }
}
