// /Views/Components/SaveLocationSheet.swift

import SwiftUI
import CoreLocation

struct SaveLocationSheet: View {
    let address: String
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    let onSave: (String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var comment: String = ""
    @State private var showCommentField: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
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
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Save Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Add this place to your collection")
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
                            
                            Text(address)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Coordinates")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                Text(formatCoordinates(coordinate))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .monospaced()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Altitude")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                Text(altitude.isNaN ? "--- m" : String(format: "%.1f m", altitude))
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
                    
                    // Comment Section with Speech-to-Text
                    VStack(spacing: 16) {
                        // Add Comment Toggle Button
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
                                    Image(systemName: "plus.circle")
                                        .font(.title3)
                                    Text("Add a comment")
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
                            VStack(alignment: .leading, spacing: 16) {
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
                                
                                // Text Field
                                TextField("Hva gjør dette stedet spesielt? / What makes this place special?", text: $comment, axis: .vertical)
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
                                
                                // Speech-to-Text Button
                                SpeechToTextButton(
                                    text: $comment,
                                    placeholder: "Trykk for å snakke din kommentar",
                                    onTextChanged: { newText in
                                        // Optional: Handle text changes if needed
                                    }
                                )
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
                        // Save Button
                        Button(action: {
                            let finalComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
                            onSave(finalComment.isEmpty ? nil : finalComment)
                            dismiss()
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }) {
                            Text("Save Location")
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
    
    // MARK: - Helper Function for Safe Coordinate Formatting
    private func formatCoordinates(_ coordinate: CLLocationCoordinate2D) -> String {
        let lat = coordinate.latitude.isNaN ? "---.----" : String(format: "%.4f", coordinate.latitude)
        let lng = coordinate.longitude.isNaN ? "---.----" : String(format: "%.4f", coordinate.longitude)
        return "\(lat), \(lng)"
    }
}

#Preview {
    SaveLocationSheet(
        address: "Apple Park, Cupertino, CA 95014",
        coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        altitude: 56.7,
        onSave: { _ in }
    )
    .preferredColorScheme(.dark)
}
