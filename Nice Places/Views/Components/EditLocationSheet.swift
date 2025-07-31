// /Views/Components/EditLocationSheet.swift

import SwiftUI
import CoreLocation

struct EditLocationSheet: View {
    let location: LocationData
    let onUpdate: (LocationData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var comment: String
    @State private var showCommentField: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    // Initialize with existing comment
    init(location: LocationData, onUpdate: @escaping (LocationData) -> Void) {
        self.location = location
        self.onUpdate = onUpdate
        
        // Pre-fill comment if it exists
        self._comment = State(initialValue: location.comment ?? "")
        self._showCommentField = State(initialValue: location.comment != nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Spotify background
                LinearGradient(
                    colors: [
                        Color.spotifyDarkGray,
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Edit Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Update your saved place")
                            .font(.subheadline)
                            .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.top, 20)
                    
                    // Location Preview Card
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.spotifyTextGray)
                            
                            Text(location.address)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Saved")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                Text(location.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Altitude")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                Text(location.altitude.isNaN ? "--- m" : String(format: "%.1f m", location.altitude))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .monospaced()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.spotifyMediumGray)
                    )
                    .padding(.horizontal, 24)
                    
                    // Comment Section
                    VStack(spacing: 16) {
                        // Add/Edit Comment Toggle Button
                        if !showCommentField {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showCommentField = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isTextFieldFocused = true
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: location.comment != nil ? "pencil.circle" : "plus.circle")
                                        .font(.title3)
                                    Text(location.comment != nil ? "Edit comment" : "Add a comment")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.spotifyGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spotifyGreen, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Comment Text Field (animated)
                        if showCommentField {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Comment")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button("Remove") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showCommentField = false
                                            comment = ""
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                }
                                
                                TextField("What makes this place special?", text: $comment, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyLightGray)
                                    )
                                    .focused($isTextFieldFocused)
                                    .lineLimit(3...6)
                            }
                            .padding(.horizontal, 24)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Update Button
                        Button(action: {
                            let finalComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Create updated location preserving original ID and timestamp
                            let updatedLocation = LocationData(
                                id: location.id, // Preserve original ID
                                address: location.address,
                                coordinate: location.coordinate,
                                altitude: location.altitude,
                                timestamp: location.timestamp, // Preserve original timestamp
                                comment: finalComment.isEmpty ? nil : finalComment,
                                photoIdentifiers: location.photoIdentifiers // Preserve photos
                            )
                            
                            onUpdate(updatedLocation)
                            dismiss()
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }) {
                            Text("Update Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.spotifyGreen)
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        // Cancel Button
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

#Preview {
    EditLocationSheet(
        location: LocationData(
            address: "Apple Park, Cupertino, CA 95014",
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            altitude: 56.7,
            comment: "Amazing architecture and great coffee!"
        ),
        onUpdate: { _ in }
    )
    .preferredColorScheme(.dark)
}
