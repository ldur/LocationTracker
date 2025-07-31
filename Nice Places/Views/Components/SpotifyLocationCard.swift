// /Views/Components/SpotifyLocationCard.swift

import SwiftUI
import CoreLocation
import MapKit

struct SpotifyLocationCard: View {
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let altitude: Double?
    let isUpdating: Bool
    
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
                    
                    Text(coordinate?.latitude != nil && !coordinate!.latitude.isNaN ? String(format: "%.6f", coordinate!.latitude) : "---.------")
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
                    
                    Text(coordinate?.longitude != nil && !coordinate!.longitude.isNaN ? String(format: "%.6f", coordinate!.longitude) : "---.------")
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
                    
                    Text(altitude != nil && !altitude!.isNaN ? String(format: "%.1f m", altitude!) : "--- m")
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
}

#Preview {
    SpotifyLocationCard(
        address: "123 Main Street, Cupertino, CA 95014",
        coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        altitude: 56.7,
        isUpdating: true
    )
    .preferredColorScheme(.dark)
}
