// /Views/Components/SpotifyLocationCard.swift

import SwiftUI
import CoreLocation
import MapKit

struct SpotifyLocationCard: View {
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let altitude: Double?
    let isUpdating: Bool
    
    // NEW: Action handlers
    let onViewMap: () -> Void
    let onSharePosition: () -> Void
    let onCapturePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.title)
                        .foregroundColor(.spotifyGreen)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Location")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(isUpdating ? "Updating..." : "Last Updated")
                            .font(.caption)
                            .foregroundColor(.spotifyTextGray)
                    }
                    
                    Spacer()
                    
                    // NEW: Action buttons integrated into the card
                    if coordinate != nil {
                        HStack(spacing: 8) {
                            // Capture Photo Button
                            Button(action: onCapturePhoto) {
                                Image(systemName: "camera.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.spotifyGreen.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // Share Position Button
                            Button(action: onSharePosition) {
                                Image(systemName: "location.fill.viewfinder")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.spotifyGreen.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // View Map Button
                            Button(action: onViewMap) {
                                Image(systemName: "map.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.spotifyGreen.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Address Display
                Text(address)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [
                        Color.spotifyMediumGray,
                        Color.spotifyLightGray.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Coordinates Section
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Latitude")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(formatCoordinate(coordinate?.latitude))
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.spotifyTextGray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 8) {
                    Text("Longitude")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(formatCoordinate(coordinate?.longitude))
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.spotifyTextGray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 8) {
                    Text("Altitude")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.spotifyTextGray)
                    
                    Text(formatAltitude(altitude))
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .background(Color.spotifyLightGray.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Functions for Safe Number Formatting
    private func formatCoordinate(_ coordinate: Double?) -> String {
        guard let coordinate = coordinate,
              coordinate.isFinite && !coordinate.isNaN else {
            return "---.------"
        }
        return String(format: "%.6f", coordinate)
    }
    
    private func formatAltitude(_ altitude: Double?) -> String {
        guard let altitude = altitude,
              altitude.isFinite && !altitude.isNaN else {
            return "--- m"
        }
        return String(format: "%.1f m", altitude)
    }
}

#Preview {
    SpotifyLocationCard(
        address: "123 Main Street, Cupertino, CA 95014",
        coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        altitude: 56.7,
        isUpdating: true,
        onViewMap: {},
        onSharePosition: {},
        onCapturePhoto: {}
    )
    .preferredColorScheme(.dark)
}
