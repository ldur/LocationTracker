
# Nice Places iOS App – Architecture Overview

## Project Overview

**Nice Places** is an iOS app built with SwiftUI that allows users to track and save locations, associate photos and trips, and interact with Spotify for enhanced location-based experiences. The app includes functionality for location tracking, trip management, media access, profile handling, and navigation.

---

## Directory Structure

```plaintext
Nice Places/
├── App/                     # Entry point of the app
├── Assets.xcassets/        # App icons and assets
├── Extentions/             # SwiftUI extensions
├── Managers/               # Singleton services for managing app logic
├── Models/                 # Data models
├── Views/                  # UI components and views
```

---

## Key Components

### App Entry

- **LocationTrackerApp.swift**: Defines the main entry point and the app lifecycle using SwiftUI's `@main` annotation.

---

### Extensions

- **Color+Spotify.swift**: Custom color definitions for Spotify-themed UI components.

---

### Managers

Manages core logic and app state. All managers are designed as singletons or services:

- **DataManager**: Central coordinator for saving/loading app data.
- **LocationManager**: Interfaces with `CoreLocation` to get and update user position.
- **NavigationManager**: Handles routing and navigation.
- **PhotoManager**: Access and selection of photos.
- **ProfileManager**: Stores and updates user profile information.
- **TripManager**: Handles trip creation, updates, and deletion.

---

### Models

Defines Codable-compliant data structures used across the app:

- **LocationData.swift**: Encapsulates location metadata (coordinates, images, name, etc.).
- **Trip.swift**: Data model for organizing sets of locations into trips.
- **UserProfile.swift**: Stores user name, contact, and preferences.

---

### Views

All SwiftUI-based user interface components:

#### Root and Navigation

- **ContentView.swift**: Root view that holds the main app UI.
- **Navigation/**: Enhancements to display routing and path visualization.

#### Components

- Reusable UI elements:
  - **MapView.swift**
  - **CameraView.swift**
  - **MediaLibraryPicker.swift**
  - **SpotifyLocationCard.swift**
  - **SaveLocationSheet.swift**
  - **NavigationLauncher.swift**
  - and others.

#### Feature-Specific Views

- **ProfileView.swift**: Displays user profile.
- **SpotifySavedLocationsView.swift**: Integrates saved locations with Spotify data.
- **Trips/**: UI for managing and exploring trips.

---

## Architecture Pattern

The app follows a **modular SwiftUI architecture** with:

- **MVVM-ish** separation:
  - View-specific state is held locally using `@State` and `@ObservedObject`.
  - Global/shared logic is encapsulated in manager singletons.
- **Dependency Injection** is manual (managers are accessed directly).
- **SwiftUI-native navigation** for user flow.
- **CoreLocation** and **MapKit** for maps and location.
- **PhotosUI**, **Contacts**, and **MusicKit/Spotify** integrations.

---

## Suggestions for Improvement

- Introduce a central `ViewModel` layer for each view to decouple UI and logic more cleanly.
- Use `EnvironmentObject` or dependency injection to avoid tight coupling with singletons.
- Add unit tests and UI tests (folders exist but are empty).
- Integrate Combine for reactive state handling where needed.

---

## Tests

The folders `Nice PlacesTests/` and `Nice PlacesUITests/` exist but are currently empty. Consider adding tests for:

- Location services
- Trip saving/loading logic
- UI flows and edge cases

---

## Documentation

An additional PDF file `Nice Places App - Architecture Summary.pdf` exists and may contain more visual elements of the system architecture.

---
