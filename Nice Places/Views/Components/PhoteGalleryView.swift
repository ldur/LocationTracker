// /Views/Components/PhotoGalleryView.swift

import SwiftUI
import Photos

// MARK: - Photo Grid View
struct PhotoGridView: View {
    let photoIdentifiers: [String]
    let photoManager: PhotoManager
    let onPhotoTap: (Int) -> Void
    
    @State private var thumbnails: [String: UIImage] = [:]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(photoIdentifiers.enumerated()), id: \.offset) { index, identifier in
                PhotoThumbnailView(
                    identifier: identifier,
                    photoManager: photoManager,
                    onTap: {
                        onPhotoTap(index)
                    }
                )
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Photo Thumbnail View
struct PhotoThumbnailView: View {
    let identifier: String
    let photoManager: PhotoManager
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var isVideo: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.spotifyMediumGray)
                        .frame(height: 120)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.spotifyGreen)
                        )
                }
                
                // Video indicator
                if isVideo {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
            checkIfVideo()
        }
    }
    
    private func loadThumbnail() {
        Task {
            let image = await photoManager.loadThumbnail(for: identifier, size: CGSize(width: 120, height: 120))
            await MainActor.run {
                self.thumbnail = image
            }
        }
    }
    
    private func checkIfVideo() {
        if let asset = photoManager.getAsset(for: identifier) {
            isVideo = asset.mediaType == .video
        }
    }
}

// MARK: - Full Screen Photo/Video Viewer
struct PhotoViewerSheet: View {
    let photoIdentifiers: [String]
    let initialIndex: Int
    let photoManager: PhotoManager
    let onDismiss: () -> Void
    
    @State private var currentIndex: Int
    @State private var currentImage: UIImage?
    @State private var isLoading = false
    
    init(photoIdentifiers: [String], initialIndex: Int, photoManager: PhotoManager, onDismiss: @escaping () -> Void) {
        self.photoIdentifiers = photoIdentifiers
        self.initialIndex = initialIndex
        self.photoManager = photoManager
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                } else if let currentImage = currentImage {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photoIdentifiers.enumerated()), id: \.offset) { index, identifier in
                            PhotoViewerPage(
                                identifier: identifier,
                                photoManager: photoManager,
                                isCurrentPage: index == currentIndex
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _, newIndex in
                        loadCurrentImage()
                    }
                } else {
                    Text("Unable to load image")
                        .foregroundColor(.white)
                }
                
                // Image counter
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(currentIndex + 1) of \(photoIdentifiers.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.6))
                            )
                            .padding(.bottom, 50)
                    }
                    .padding(.trailing, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: shareCurrentImage) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: deleteCurrentImage) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            loadCurrentImage()
        }
    }
    
    private func loadCurrentImage() {
        guard currentIndex < photoIdentifiers.count else { return }
        
        isLoading = true
        let identifier = photoIdentifiers[currentIndex]
        
        Task {
            let image = await photoManager.loadFullImage(for: identifier)
            await MainActor.run {
                self.currentImage = image
                self.isLoading = false
            }
        }
    }
    
    private func shareCurrentImage() {
        guard let image = currentImage else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func deleteCurrentImage() {
        guard currentIndex < photoIdentifiers.count else { return }
        
        let identifier = photoIdentifiers[currentIndex]
        
        Task {
            let success = await photoManager.deleteAssets(with: [identifier])
            if success {
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Individual Photo/Video Page
struct PhotoViewerPage: View {
    let identifier: String
    let photoManager: PhotoManager
    let isCurrentPage: Bool
    
    @State private var image: UIImage?
    @State private var isVideo: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var magnification: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if let image = image {
                if isVideo {
                    // Video thumbnail with play button
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale * magnification)
                            .offset(offset)
                        
                        Button(action: playVideo) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                    }
                } else {
                    // Photo with zoom functionality
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale * magnification)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .updating($magnification) { currentState, gestureState, transaction in
                                    gestureState = currentState
                                }
                                .onEnded { value in
                                    scale *= value
                                    scale = min(max(scale, 1.0), 5.0)
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        offset = .zero
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1.0 ? 1.0 : 2.0
                                offset = .zero
                            }
                        }
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .onAppear {
            if isCurrentPage {
                loadImage()
                checkIfVideo()
            }
        }
        .onChange(of: isCurrentPage) { _, newValue in
            if newValue {
                loadImage()
                checkIfVideo()
            }
        }
    }
    
    private func loadImage() {
        Task {
            let loadedImage = await photoManager.loadFullImage(for: identifier)
            await MainActor.run {
                self.image = loadedImage
            }
        }
    }
    
    private func checkIfVideo() {
        if let asset = photoManager.getAsset(for: identifier) {
            isVideo = asset.mediaType == .video
        }
    }
    
    private func playVideo() {
        // Check if we have a valid video asset
        guard photoManager.getAsset(for: identifier) != nil else {
            print("No video asset found for identifier: \(identifier)")
            return
        }
        
        // TODO: Implement video playback
        // For now, we'll use the system photo viewer
        // Could implement AVPlayerViewController here in the future
        print("Video playback not yet implemented for identifier: \(identifier)")
    }
}

#Preview {
    PhotoGridView(
        photoIdentifiers: ["sample1", "sample2", "sample3"],
        photoManager: PhotoManager(),
        onPhotoTap: { _ in }
    )
    .preferredColorScheme(.dark)
}
