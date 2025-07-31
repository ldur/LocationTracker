// /Views/Components/CameraView.swift

import SwiftUI
import UIKit
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onVideoCaptured: (URL) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 60 // 1 minute max
        picker.allowsEditing = true
        
        // Custom camera overlay for better UX
        picker.showsCameraControls = true
        picker.cameraOverlayView = createCameraOverlay()
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createCameraOverlay() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = .clear
        
        // Add location indicator
        let locationLabel = UILabel()
        locationLabel.text = "📍 Capturing for location"
        locationLabel.textColor = .white
        locationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        locationLabel.layer.cornerRadius = 8
        locationLabel.clipsToBounds = true
        locationLabel.textAlignment = .center
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        overlayView.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: overlayView.safeAreaLayoutGuide.topAnchor, constant: 20),
            locationLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            locationLabel.widthAnchor.constraint(equalToConstant: 200),
            locationLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return overlayView
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoCaptured(videoURL)
            }
            
            parent.onDismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}

// MARK: - Camera Permission Helper
struct CameraPermissionView: View {
    let onPermissionGranted: () -> Void
    let onDismiss: () -> Void
    
    @State private var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.spotifyGreen)
                    
                    Text("Camera Access Needed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("To capture photos and videos for your locations, we need access to your camera.")
                        .font(.body)
                        .foregroundColor(.spotifyTextGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        Button(action: requestCameraPermission) {
                            Text("Enable Camera")
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
                        
                        Button("Not Now") {
                            onDismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    onPermissionGranted()
                } else {
                    // Could show settings redirect here
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Photo/Video Capture Sheet
struct PhotoCaptureSheet: View {
    let onImageCaptured: (UIImage) -> Void
    let onVideoCaptured: (URL) -> Void
    let onDismiss: () -> Void
    
    @State private var showingCamera = false
    @State private var showingPermissionView = false
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Capture Memories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Take photos and videos of this special place")
                            .font(.subheadline)
                            .foregroundColor(.spotifyTextGray)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: openCamera) {
                            HStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Open Camera")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Take photos and videos")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.spotifyGreen)
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(
                onImageCaptured: onImageCaptured,
                onVideoCaptured: onVideoCaptured,
                onDismiss: {
                    showingCamera = false
                    onDismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showingPermissionView) {
            CameraPermissionView(
                onPermissionGranted: {
                    showingPermissionView = false
                    showingCamera = true
                },
                onDismiss: {
                    showingPermissionView = false
                    onDismiss()
                }
            )
        }
    }
    
    private func openCamera() {
        switch cameraPermission {
        case .authorized:
            showingCamera = true
        case .notDetermined, .denied:
            showingPermissionView = true
        default:
            break
        }
    }
}

#Preview {
    PhotoCaptureSheet(
        onImageCaptured: { _ in },
        onVideoCaptured: { _ in },
        onDismiss: {}
    )
}
