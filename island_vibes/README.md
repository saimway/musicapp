# Island Vibes

A fancy local music player for Android with a Dynamic Island overlay.

## Setup Instructions

**Important:** Because this project structure was created manually, you might need to configure the SDK paths before running.

1.  **Configure SDK Paths:**
    *   Open `island_vibes/android/local.properties`.
    *   Update `sdk.dir` to point to your Android SDK location.
        *   *Windows Example:* `C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk`
        *   *Mac Example:* `/Users/YourName/Library/Android/sdk`
    *   Update `flutter.sdk` to point to your Flutter SDK location.

    *Alternatively, opening the `android` folder in **Android Studio** will often generate this file for you automatically.*

2.  **Dependencies:**
    *   Run `flutter pub get` inside the `island_vibes` folder.

3.  **Run:**
    *   `flutter run`

## Features

*   **Dynamic Island:** A system-wide overlay that shows music info and animations.
*   **Organizer:** Filter music by Artist or Album.
*   **Audio Service:** Background playback support.
*   **Modern UI:** Dark theme with smooth animations.
