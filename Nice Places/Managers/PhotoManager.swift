// /Managers/PhotoManager.swift

import Foundation
import Photos
import UIKit
import SwiftUI

@Observable
class PhotoManager: NSObject {
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var placesAlbum: PHAssetCollection?
    var errorMessage: String?
    
    private let albumName = "Nice Places"
    private let imageManager = PHImageManager.default()
    
    override init() {
        super.init()
        checkPhotoLibraryPermission()
        Task {
            await createPlacesAlbumIfNeeded()
        }
    }
    
    // MARK: - Permission Management
    func checkPhotoLibraryPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        await MainActor.run {
            authorizationStatus = status
        }
        return status == .authorized
    }
    
    // MARK: - Album Management
    @MainActor
    private func createPlacesAlbumIfNeeded() async {
        // Check if album already exists
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = collection.firstObject {
            placesAlbum = existingAlbum
            return
        }
        
        // Create new album
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
            }
            
            // Fetch the newly created album
            let newCollection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            placesAlbum = newCollection.firstObject
        } catch {
            errorMessage = "Failed to create album: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Photo/Video Saving
    func saveImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard authorizationStatus == .authorized else {
            Task {
                let granted = await requestPhotoLibraryPermission()
                if granted {
                    saveImage(image, completion: completion)
                } else {
                    await MainActor.run {
                        errorMessage = "Photo library access denied"
                        completion(nil)
                    }
                }
            }
            return
        }
        
        Task {
            do {
                // Capture the identifier before the performChanges block
                var capturedIdentifier: String?
                
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    
                    // Store the identifier immediately
                    capturedIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
                    
                    // Add to custom album if available
                    if let album = self.placesAlbum,
                       let placeholder = creationRequest.placeholderForCreatedAsset {
                        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                        albumChangeRequest?.addAssets([placeholder] as NSArray)
                    }
                }
                
                await MainActor.run {
                    completion(capturedIdentifier)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save image: \(error.localizedDescription)"
                    completion(nil)
                }
            }
        }
    }
    
    func saveVideo(from url: URL, completion: @escaping (String?) -> Void) {
        guard authorizationStatus == .authorized else {
            Task {
                let granted = await requestPhotoLibraryPermission()
                if granted {
                    saveVideo(from: url, completion: completion)
                } else {
                    await MainActor.run {
                        errorMessage = "Photo library access denied"
                        completion(nil)
                    }
                }
            }
            return
        }
        
        Task {
            do {
                // Capture the identifier before the performChanges block
                var capturedIdentifier: String?
                
                try await PHPhotoLibrary.shared().performChanges {
                    let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    
                    // Store the identifier immediately
                    capturedIdentifier = creationRequest?.placeholderForCreatedAsset?.localIdentifier
                    
                    // Add to custom album if available
                    if let album = self.placesAlbum,
                       let placeholder = creationRequest?.placeholderForCreatedAsset {
                        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                        albumChangeRequest?.addAssets([placeholder] as NSArray)
                    }
                }
                
                await MainActor.run {
                    completion(capturedIdentifier)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save video: \(error.localizedDescription)"
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Photo/Video Loading
    func loadThumbnail(for identifier: String, size: CGSize = CGSize(width: 100, height: 100)) async -> UIImage? {
        print("📸 PhotoManager: Attempting to load thumbnail for identifier: \(identifier)")
        
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: fetchOptions)
        
        guard let asset = assets.firstObject else {
            print("❌ PhotoManager: No asset found for identifier: \(identifier)")
            return nil
        }
        
        print("✅ PhotoManager: Found asset for identifier: \(identifier), mediaType: \(asset.mediaType.rawValue)")
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic // Allow multiple callbacks for better UX
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true // Allow network access for iCloud photos
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            let requestID = imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                print("📸 PhotoManager: Received image callback for \(identifier)")
                print("📸 PhotoManager: Image: \(image != nil ? "✅ Available" : "❌ Nil")")
                
                if let info = info {
                    let isDegraded = (info[PHImageResultIsDegradedKey] as? Bool) ?? false
                    let isCancelled = (info[PHImageCancelledKey] as? Bool) ?? false
                    let hasError = (info[PHImageErrorKey] != nil)
                    
                    print("📸 PhotoManager: isDegraded: \(isDegraded), isCancelled: \(isCancelled), hasError: \(hasError)")
                    
                    if let error = info[PHImageErrorKey] as? Error {
                        print("❌ PhotoManager: Error loading image: \(error)")
                    }
                }
                
                guard !hasResumed else {
                    print("📸 PhotoManager: Already resumed, ignoring callback")
                    return
                }
                
                // For thumbnails, take the first available image
                if let image = image {
                    hasResumed = true
                    print("✅ PhotoManager: Successfully loaded thumbnail for \(identifier)")
                    continuation.resume(returning: image)
                } else if let info = info {
                    let isCancelled = (info[PHImageCancelledKey] as? Bool) ?? false
                    let hasError = (info[PHImageErrorKey] != nil)
                    
                    if isCancelled || hasError {
                        hasResumed = true
                        print("❌ PhotoManager: Failed to load thumbnail - cancelled: \(isCancelled), error: \(hasError)")
                        continuation.resume(returning: nil)
                    }
                }
            }
            
            print("📸 PhotoManager: Started image request with ID: \(requestID)")
        }
    }
    
    func loadFullImage(for identifier: String) async -> UIImage? {
        print("📸 PhotoManager: Loading full image for identifier: \(identifier)")
        
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            print("❌ PhotoManager: No asset found for full image: \(identifier)")
            return nil
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = (info?[PHImageErrorKey] != nil)
                
                if !isDegraded || isCancelled || hasError {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }
    
    func getAsset(for identifier: String) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }
    
    // MARK: - Asset Management
    func deleteAssets(with identifiers: [String]) async -> Bool {
        guard !identifiers.isEmpty else { return true }
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        guard assets.count > 0 else { return true }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete photos: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Utility
    func hasPhotos(for identifiers: [String]) -> Bool {
        return !identifiers.isEmpty
    }
    
    func photoCount(for identifiers: [String]) -> Int {
        return identifiers.count
    }
}
