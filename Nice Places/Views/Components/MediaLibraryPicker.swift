// /Views/Components/MediaLibraryPicker.swift

import SwiftUI
import PhotosUI
import Photos

struct MediaLibraryPicker: UIViewControllerRepresentable {
    let onMediaSelected: ([PHAsset]) -> Void
    let onDismiss: () -> Void
    let maxSelectionCount: Int
    
    init(maxSelectionCount: Int = 10, onMediaSelected: @escaping ([PHAsset]) -> Void, onDismiss: @escaping () -> Void) {
        self.maxSelectionCount = maxSelectionCount
        self.onMediaSelected = onMediaSelected
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = PHPickerFilter.any(of: [.images, .videos])
        configuration.selectionLimit = maxSelectionCount
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaLibraryPicker
        
        init(_ parent: MediaLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.onDismiss()
            
            guard !results.isEmpty else { return }
            
            // Convert PHPickerResults to PHAssets
            let assetIdentifiers = results.compactMap { result in
                result.assetIdentifier
            }
            
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
            var assets: [PHAsset] = []
            
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            if !assets.isEmpty {
                parent.onMediaSelected(assets)
            }
        }
    }
}

// MARK: - Media Library Access Sheet
struct MediaLibraryAccessSheet: View {
    let onMediaSelected: ([PHAsset]) -> Void
    let onDismiss: () -> Void
    let maxSelectionCount: Int
    
    @State private var showingPicker = false
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    init(maxSelectionCount: Int = 10, onMediaSelected: @escaping ([PHAsset]) -> Void, onDismiss: @escaping () -> Void) {
        self.maxSelectionCount = maxSelectionCount
        self.onMediaSelected = onMediaSelected
        self.onDismiss = onDismiss
    }
    
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
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.spotifyGreen)
                        
                        Text("Add from Library")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Select photos and videos from your library")
                            .font(.subheadline)
                            .foregroundColor(.spotifyTextGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Info Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(.spotifyGreen)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Media Selection")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Choose up to \(maxSelectionCount) photos or videos")
                                    .font(.subheadline)
                                    .foregroundColor(.spotifyTextGray)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Supported formats:")
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                        .foregroundColor(.spotifyGreen)
                                    Text("Photos")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "video")
                                        .font(.caption)
                                        .foregroundColor(.spotifyGreen)
                                    Text("Videos")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.spotifyMediumGray.opacity(0.6))
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: openMediaPicker) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                
                                Text("Choose from Library")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.spotifyGreen)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Button("Cancel") {
                            onDismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            checkPhotoLibraryPermission()
        }
        .fullScreenCover(isPresented: $showingPicker) {
            MediaLibraryPicker(
                maxSelectionCount: maxSelectionCount,
                onMediaSelected: onMediaSelected,
                onDismiss: { showingPicker = false }
            )
        }
    }
    
    private func checkPhotoLibraryPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func openMediaPicker() {
        switch authorizationStatus {
        case .authorized, .limited:
            showingPicker = true
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            // Could show settings alert here
            onDismiss()
        @unknown default:
            onDismiss()
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                if status == .authorized || status == .limited {
                    self.showingPicker = true
                } else {
                    self.onDismiss()
                }
            }
        }
    }
}

#Preview {
    MediaLibraryAccessSheet(
        onMediaSelected: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
