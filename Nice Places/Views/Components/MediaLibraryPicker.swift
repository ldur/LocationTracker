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
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = PHPickerFilter.any(of: [.images, .videos])
        configuration.selectionLimit = maxSelectionCount
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        
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
            guard !results.isEmpty else {
                print("📸 MediaLibraryPicker: User cancelled or selected no items")
                self.parent.onDismiss()
                return
            }
            
            print("📸 MediaLibraryPicker: User selected \(results.count) items")
            
            // Only process items that have valid assetIdentifiers (no copying!)
            let validResults = results.compactMap { result -> String? in
                if let identifier = result.assetIdentifier {
                    print("✅ Found valid assetIdentifier: \(identifier)")
                    return identifier
                } else {
                    print("⚠️ Skipping item without assetIdentifier - will not create copy")
                    return nil
                }
            }
            
            guard !validResults.isEmpty else {
                print("❌ No photos with valid identifiers - cannot reference without copying")
                self.parent.onDismiss()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showCannotReferenceAlert(totalSelected: results.count)
                }
                return
            }
            
            // Fetch the actual PHAsset objects
            print("📸 Fetching PHAssets for \(validResults.count) identifiers...")
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: validResults, options: nil)
            var assets: [PHAsset] = []
            
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            if !assets.isEmpty {
                print("✅ Successfully referenced \(assets.count) existing photos (no copies created)")
                
                let skippedCount = results.count - assets.count
                if skippedCount > 0 {
                    print("⚠️ Skipped \(skippedCount) photos that couldn't be referenced")
                }
                
                self.parent.onDismiss()
                self.parent.onMediaSelected(assets)
            } else {
                print("❌ Failed to fetch any PHAssets")
                self.parent.onDismiss()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showFetchFailedAlert()
                }
            }
        }
        
        private func processItemsAsImages(_ results: [PHPickerResult], completion: @escaping ([PHAsset]) -> Void) {
            print("📸 Processing \(results.count) items as images...")
            
            let group = DispatchGroup()
            var processedAssets: [PHAsset] = []
            let assetsLock = NSLock() // Thread safety for the array
            
            for (index, result) in results.enumerated() {
                group.enter()
                
                print("📸 Processing item \(index)...")
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            print("✅ Loaded UIImage for item \(index), saving to library...")
                            self.saveImageToLibrary(image) { asset in
                                if let asset = asset {
                                    assetsLock.lock()
                                    processedAssets.append(asset)
                                    assetsLock.unlock()
                                    print("✅ Saved and got PHAsset for item \(index)")
                                } else {
                                    print("❌ Failed to save item \(index)")
                                }
                                group.leave() // Leave AFTER save operation completes
                            }
                        } else {
                            print("❌ Failed to load UIImage for item \(index): \(error?.localizedDescription ?? "Unknown error")")
                            group.leave()
                        }
                    }
                } else {
                    print("❌ Item \(index) cannot be loaded as UIImage")
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                print("📸 Finished processing all items. Got \(processedAssets.count) assets")
                completion(processedAssets)
            }
        }
        
        private func saveImageToLibrary(_ image: UIImage, completion: @escaping (PHAsset?) -> Void) {
            // Use PhotoManager if available to save to Nice Places album
            if let photoManager = self.photoManager {
                print("📸 Using PhotoManager to save to Nice Places album...")
                photoManager.saveImage(image) { identifier in
                    if let identifier = identifier {
                        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                        DispatchQueue.main.async {
                            completion(fetchResult.firstObject)
                        }
                    } else {
                        print("❌ PhotoManager failed to save image")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            } else {
                // Fallback to direct library save
                print("📸 Saving directly to photo library...")
                var assetIdentifier: String?
                
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    assetIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
                }) { success, error in
                    if success, let identifier = assetIdentifier {
                        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                        DispatchQueue.main.async {
                            completion(fetchResult.firstObject)
                        }
                    } else {
                        print("❌ Failed to save image: \(error?.localizedDescription ?? "Unknown error")")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
        
        private func showCannotReferenceAlert(totalSelected: Int) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                print("❌ Could not find root view controller for alert")
                return
            }
            
            let message = totalSelected == 1
                ? "The selected photo cannot be referenced directly. This happens with:\n\n• iCloud photos not fully downloaded\n• Photos in shared albums\n• System-managed photos\n\nPlease try selecting photos from your 'Recents' album or photos taken directly with this device."
                : "The selected photos cannot be referenced directly. This happens with:\n\n• iCloud photos not fully downloaded\n• Photos in shared albums\n• System-managed photos\n\nPlease try selecting photos from your 'Recents' album or photos taken directly with this device."
            
            let alert = UIAlertController(
                title: "Cannot Reference Photos",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Find the top-most view controller that can present
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            if topController.view.window != nil {
                topController.present(alert, animated: true)
            } else {
                rootViewController.present(alert, animated: true)
            }
        }
        
        private func showFetchFailedAlert() {
            // Find the active window and present the alert
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                print("❌ Could not find root view controller for alert")
                return
            }
            
            let alert = UIAlertController(
                title: "Photos Not Available",
                message: "The selected photos could not be accessed. Please try again or select different photos from your 'Recents' album.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Find the top-most view controller that can present
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            // Ensure we can present on this controller
            if topController.view.window != nil {
                topController.present(alert, animated: true)
            } else {
                // Fallback: present on root controller
                rootViewController.present(alert, animated: true)
            }
        }
    }
}

// MARK: - Media Library Access Sheet (UPDATED)
struct MediaLibraryAccessSheet: View {
    let onMediaSelected: ([PHAsset]) -> Void
    let onDismiss: () -> Void
    let maxSelectionCount: Int
    let locationContext: String? // Optional context for better UX
    
    @State private var showingPicker = false
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var isProcessing = false // Processing state
    
    init(maxSelectionCount: Int = 10, locationContext: String? = nil, onMediaSelected: @escaping ([PHAsset]) -> Void, onDismiss: @escaping () -> Void) {
        self.maxSelectionCount = maxSelectionCount
        self.locationContext = locationContext
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
                
                if isProcessing {
                    // Processing overlay
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.spotifyGreen)
                        
                        Text("Adding Photos...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let context = locationContext {
                            Text("to \(context)")
                                .font(.subheadline)
                                .foregroundColor(.spotifyTextGray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.8))
                } else {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.spotifyGreen)
                            
                            VStack(spacing: 8) {
                                Text("Add from Library")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if let context = locationContext {
                                    Text("Adding to: \(context)")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyGreen)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .padding(.horizontal, 20)
                                } else {
                                    Text("Select photos and videos from your library")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyTextGray)
                                        .multilineTextAlignment(.center)
                                }
                            }
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
                                
                                // Updated note about photo referencing (no copying)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("Important:")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("Photos are referenced directly from your library without creating copies. Only locally stored photos can be referenced.")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                }
                            }
                            
                            // Quick tip
                            if locationContext != nil {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lightbulb")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("Tip:")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Text("Selected photos will be linked to this location without creating duplicates")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
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
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            checkPhotoLibraryPermission()
        }
        .fullScreenCover(isPresented: $showingPicker) {
            MediaLibraryPicker(
                maxSelectionCount: maxSelectionCount,
                onMediaSelected: { assets in
                    handleMediaSelection(assets)
                },
                onDismiss: {
                    showingPicker = false
                }
            )
        }
    }
    
    private func checkPhotoLibraryPermission() {
        // Request readWrite permission to access existing photos
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func openMediaPicker() {
        switch authorizationStatus {
        case .authorized, .limited:
            showingPicker = true
        case .notDetermined:
            requestPhotoLibraryPermission()
        case .denied, .restricted:
            showPermissionDeniedAlert()
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
                    self.showPermissionDeniedAlert()
                }
            }
        }
    }
    
    private func showPermissionDeniedAlert() {
        // Show alert directing user to settings
        let alert = UIAlertController(
            title: "Photo Access Required",
            message: "To add photos from your library, please allow photo access in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.onDismiss()
        })
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(alert, animated: true)
        }
    }
    
    // NEW: Handle media selection with processing state
    private func handleMediaSelection(_ assets: [PHAsset]) {
        guard !assets.isEmpty else {
            onDismiss()
            return
        }
        
        // Show processing state
        isProcessing = true
        
        // Add a small delay to show the processing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onMediaSelected(assets)
            
            // Delay dismissal to show completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.onDismiss()
            }
        }
    }
}

#Preview {
    MediaLibraryAccessSheet(
        locationContext: "Apple Park, Cupertino, CA",
        onMediaSelected: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
