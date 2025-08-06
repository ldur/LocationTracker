// /Managers/NavigationManager.swift

import Foundation
import SwiftUI
import CoreLocation
import MapKit

@Observable
class NavigationManager: NSObject {
    // Navigation State
    var isNavigating = false
    var currentTrip: Trip?
    var tripLocations: [LocationData] = []
    var currentLocationIndex = 0
    var currentRoute: MKRoute?
    var allRoutes: [MKRoute] = []
    var currentStep: MKRoute.Step?
    var remainingSteps: [MKRoute.Step] = []
    
    // User Location
    var userLocation: CLLocation?
    var userHeading: CLHeading?
    var isOnRoute = true
    var distanceToNextTurn: Double = 0
    var timeToDestination: TimeInterval = 0
    var distanceToDestination: Double = 0
    
    // Navigation Instructions
    var currentInstruction: String = ""
    var nextInstruction: String = ""
    var distanceToNextLocation: Double = 0
    var etaToNextLocation: Date?
    
    // Error Handling
    var errorMessage: String?
    var isCalculatingRoute = false
    var isRerouting = false
    
    // Thresholds
    private let offRouteThreshold: Double = 50 // meters
    private let arrivedThreshold: Double = 30 // meters
    private let instructionUpdateThreshold: Double = 100 // meters
    
    // Transport Type
    var transportType: MKDirectionsTransportType = .automobile
    
    // Location Manager
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.activityType = .automotiveNavigation
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    // MARK: - Navigation Control
    func startNavigation(for trip: Trip, locations: [LocationData], startIndex: Int = 0) async {
        print("🗺️ NavigationManager: Starting navigation for trip: \(trip.name)")
        
        currentTrip = trip
        tripLocations = locations.sorted { $0.timestamp < $1.timestamp }
        currentLocationIndex = startIndex
        isNavigating = true
        
        // Set transport type based on trip type
        switch trip.autoSaveConfig.tripType {
        case .walking:
            transportType = .walking
        case .car:
            transportType = .automobile
        case .bicycle, .custom:
            transportType = .automobile // MapKit doesn't have bicycle, use automobile
        }
        
        // Request location updates
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Calculate initial route
        await calculateFullRoute()
    }
    
    func stopNavigation() {
        print("🗺️ NavigationManager: Stopping navigation")
        
        isNavigating = false
        currentTrip = nil
        tripLocations = []
        currentLocationIndex = 0
        currentRoute = nil
        allRoutes = []
        currentStep = nil
        remainingSteps = []
        
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func skipToNextLocation() async {
        guard currentLocationIndex < tripLocations.count - 1 else {
            print("🗺️ NavigationManager: No more locations to navigate to")
            stopNavigation()
            return
        }
        
        currentLocationIndex += 1
        print("🗺️ NavigationManager: Skipping to location \(currentLocationIndex + 1) of \(tripLocations.count)")
        
        await calculateRouteToCurrentDestination()
    }
    
    // MARK: - Route Calculation
    private func calculateFullRoute() async {
        guard !tripLocations.isEmpty else { return }
        
        await MainActor.run {
            isCalculatingRoute = true
            allRoutes = []
        }
        
        // Calculate routes between all consecutive locations
        for i in 0..<(tripLocations.count - 1) {
            let start = tripLocations[i]
            let end = tripLocations[i + 1]
            
            if let route = await calculateRoute(from: start.coordinate, to: end.coordinate) {
                await MainActor.run {
                    allRoutes.append(route)
                }
            }
        }
        
        // Start navigating to the first destination
        if currentLocationIndex < tripLocations.count {
            await calculateRouteToCurrentDestination()
        }
        
        await MainActor.run {
            isCalculatingRoute = false
        }
    }
    
    private func calculateRouteToCurrentDestination() async {
        guard currentLocationIndex < tripLocations.count else { return }
        
        let destination = tripLocations[currentLocationIndex]
        let startCoordinate: CLLocationCoordinate2D
        
        if let userLocation = userLocation {
            startCoordinate = userLocation.coordinate
        } else if currentLocationIndex > 0 {
            startCoordinate = tripLocations[currentLocationIndex - 1].coordinate
        } else {
            print("🗺️ NavigationManager: No starting location available")
            return
        }
        
        await MainActor.run {
            isCalculatingRoute = true
        }
        
        if let route = await calculateRoute(from: startCoordinate, to: destination.coordinate) {
            await MainActor.run {
                self.currentRoute = route
                self.remainingSteps = Array(route.steps)
                self.updateNavigationInstructions()
                self.isCalculatingRoute = false
            }
        } else {
            await MainActor.run {
                self.errorMessage = "Failed to calculate route"
                self.isCalculatingRoute = false
            }
        }
    }
    
    private func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async -> MKRoute? {
        return await withCheckedContinuation { continuation in
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
            request.transportType = transportType
            request.requestsAlternateRoutes = false
            
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                if let error = error {
                    print("🗺️ NavigationManager: Route calculation error: \(error)")
                    continuation.resume(returning: nil)
                } else if let route = response?.routes.first {
                    print("🗺️ NavigationManager: Route calculated - Distance: \(route.distance)m, ETA: \(route.expectedTravelTime)s")
                    continuation.resume(returning: route)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Navigation Updates
    private func updateNavigationInstructions() {
        guard let route = currentRoute else { return }
        
        // Update current instruction
        if let currentStep = remainingSteps.first {
            currentInstruction = formatInstruction(currentStep.instructions)
            distanceToNextTurn = currentStep.distance
        }
        
        // Update next instruction
        if remainingSteps.count > 1 {
            nextInstruction = formatInstruction(remainingSteps[1].instructions)
        } else if currentLocationIndex < tripLocations.count - 1 {
            nextInstruction = "Continue to next location"
        } else {
            nextInstruction = "Arriving at final destination"
        }
        
        // Update ETA and distance
        distanceToDestination = route.distance
        timeToDestination = route.expectedTravelTime
        etaToNextLocation = Date().addingTimeInterval(timeToDestination)
        
        // Update distance to next location
        if currentLocationIndex < tripLocations.count,
           let userLocation = userLocation {
            let destination = CLLocation(
                latitude: tripLocations[currentLocationIndex].coordinate.latitude,
                longitude: tripLocations[currentLocationIndex].coordinate.longitude
            )
            distanceToNextLocation = userLocation.distance(from: destination)
        }
    }
    
    private func formatInstruction(_ instruction: String) -> String {
        // Clean up and format MapKit instructions
        var formatted = instruction
        
        // Remove redundant information
        formatted = formatted.replacingOccurrences(of: "onto ", with: "to ")
        formatted = formatted.replacingOccurrences(of: "  ", with: " ")
        
        // Capitalize first letter
        if !formatted.isEmpty {
            formatted = formatted.prefix(1).uppercased() + formatted.dropFirst()
        }
        
        return formatted
    }
    
    // MARK: - Location Tracking
    private func checkIfOffRoute(_ location: CLLocation) {
        guard let route = currentRoute else { return }
        
        let polyline = route.polyline
        let userPoint = MKMapPoint(location.coordinate)
        
        var minDistance = Double.greatestFiniteMagnitude
        let points = polyline.points()
        
        for i in 0..<polyline.pointCount - 1 {
            let segmentStart = points[i]
            let segmentEnd = points[i + 1]
            
            let distance = distanceFromPoint(userPoint, toSegmentFrom: segmentStart, to: segmentEnd)
            minDistance = min(minDistance, distance)
        }
        
        isOnRoute = minDistance < offRouteThreshold
        
        if !isOnRoute && !isRerouting {
            print("🗺️ NavigationManager: User is off route, recalculating...")
            Task {
                await recalculateRoute()
            }
        }
    }
    
    private func distanceFromPoint(_ point: MKMapPoint, toSegmentFrom start: MKMapPoint, to end: MKMapPoint) -> Double {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        if dx == 0 && dy == 0 {
            // Start and end are the same point
            return point.distance(to: start)
        }
        
        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / (dx * dx + dy * dy)))
        
        let projection = MKMapPoint(x: start.x + t * dx, y: start.y + t * dy)
        return point.distance(to: projection)
    }
    
    private func checkArrivalAtDestination(_ location: CLLocation) {
        guard currentLocationIndex < tripLocations.count else { return }
        
        let destination = tripLocations[currentLocationIndex]
        let destinationLocation = CLLocation(
            latitude: destination.coordinate.latitude,
            longitude: destination.coordinate.longitude
        )
        
        let distance = location.distance(from: destinationLocation)
        
        if distance < arrivedThreshold {
            print("🗺️ NavigationManager: Arrived at location \(currentLocationIndex + 1) of \(tripLocations.count)")
            
            // Haptic feedback for arrival
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Move to next location
            if currentLocationIndex < tripLocations.count - 1 {
                currentLocationIndex += 1
                Task {
                    await calculateRouteToCurrentDestination()
                }
            } else {
                // Completed all locations
                print("🗺️ NavigationManager: Navigation complete!")
                stopNavigation()
            }
        }
    }
    
    private func updateStepProgress(_ location: CLLocation) {
        guard !remainingSteps.isEmpty else { return }
        
        let currentStep = remainingSteps[0]
        
        // Calculate distance to step end point
        if let stepLocation = currentStep.polyline.coordinate as CLLocationCoordinate2D? {
            let stepEndLocation = CLLocation(latitude: stepLocation.latitude, longitude: stepLocation.longitude)
            let distanceToStepEnd = location.distance(from: stepEndLocation)
            
            // If close to step end, move to next step
            if distanceToStepEnd < 20 {
                remainingSteps.removeFirst()
                updateNavigationInstructions()
                
                // Light haptic for step completion
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        
        // Update distance to next turn
        distanceToNextTurn = max(0, distanceToNextTurn - 5) // Approximate based on update frequency
    }
    
    // MARK: - Rerouting
    private func recalculateRoute() async {
        await MainActor.run {
            isRerouting = true
        }
        
        await calculateRouteToCurrentDestination()
        
        await MainActor.run {
            isRerouting = false
        }
    }
    
    // MARK: - Utility Functions
    func getCurrentDestination() -> LocationData? {
        guard currentLocationIndex < tripLocations.count else { return nil }
        return tripLocations[currentLocationIndex]
    }
    
    func getRemainingLocations() -> [LocationData] {
        guard currentLocationIndex < tripLocations.count else { return [] }
        return Array(tripLocations[currentLocationIndex...])
    }
    
    func getCompletedLocations() -> [LocationData] {
        guard currentLocationIndex > 0 else { return [] }
        return Array(tripLocations[0..<currentLocationIndex])
    }
    
    func formatDistance(_ distance: Double) -> String {
        if distance < 100 {
            return "\(Int(distance))m"
        } else if distance < 1000 {
            return "\(Int(distance / 10) * 10)m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "< 1 min"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60)) min"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension NavigationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              isNavigating else { return }
        
        userLocation = location
        
        // Check if off route
        checkIfOffRoute(location)
        
        // Check arrival at destination
        checkArrivalAtDestination(location)
        
        // Update step progress
        updateStepProgress(location)
        
        // Update navigation instructions
        updateNavigationInstructions()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🗺️ NavigationManager: Location error: \(error)")
        errorMessage = "Location error: \(error.localizedDescription)"
    }
}

// MARK: - MKMapPoint Extension
extension MKMapPoint {
    func distance(to point: MKMapPoint) -> Double {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
