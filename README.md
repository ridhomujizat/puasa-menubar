# Puasa Menubar

A beautiful macOS menu bar application that displays daily prayer times with a Ramadan-themed green color scheme and glass-morphism design.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)

## Features

- 🕌 Real-time prayer times for your location
- 🌙 Ramadan-themed green color scheme
- ✨ Glass-morphism translucent design
- 📍 Automatic location detection
- ⏱️ Countdown to next prayer
- 📅 Hijri and Gregorian date display
- 🎯 Menu bar integration for quick access

## Prayer Times

The app displays the following prayer times:
- Fajr (فجر)
- Sunrise (شروق)
- Dhuhr (ظهر)
- Asr (عصر)
- Maghrib (مغرب)
- Isha (عشاء)
- Imsak (إمساك)

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ or Swift 5.9+
- Location services enabled

## Installation & Running

### Quick Start with run.sh

The easiest way to build and run the app:

```bash
# Make the script executable (if not already)
chmod +x run.sh

# Build and launch the app
./run.sh
```

The `run.sh` script will:
1. Build the project using Swift Package Manager
2. Package the `.app` bundle
3. Sign the app with required entitlements
4. Launch the application

### Manual Build

If you prefer to build manually:

```bash
# Build using Swift Package Manager
swift build

# Run the app
open PuasaMenubar.app
```

### Using Xcode

1. Generate Xcode project:
   ```bash
   swift package generate-xcodeproj
   ```

2. Open `PuasaMenubar.xcodeproj` in Xcode

3. Build and run (⌘R)

## Usage

1. **First Launch**: Grant location permission when prompted
2. **Menu Bar**: The app runs in your menu bar for quick access
3. **Refresh**: Click the refresh icon to update prayer times
4. **Quit**: Click the X button or quit from the menu

## Project Structure

```
PuasaMenubar/
├── Models/
│   └── PrayerTimesModel.swift    # Data models for prayer times
├── Views/
│   ├── MenuBarExtra.swift        # Main menu bar view
│   ├── PrayerTimesView.swift     # Full prayer times view
│   └── PrayerTimeRow.swift       # Individual prayer row
├── Services/
│   ├── APIService.swift          # Prayer times API client
│   ├── LocationManager.swift     # Location services
│   └── PrayerTimesViewModel.swift # View model
├── Utils/
│   └── Colors.swift              # Custom color definitions
└── Assets.xcassets               # App assets
```

## Configuration

The app uses the [Aladhan API](https://aladhan.com/prayer-times-api) to fetch prayer times based on your location.

### Color Theme

The app uses a custom Ramadan green theme:
- Primary: `ramadanGreen` (RGB: 0, 0.6, 0.4)
- Light: `ramadanGreenLight` (10% opacity)
- Dark: `ramadanGreenDark` (darker variant)

## Troubleshooting

### Location Permission Issues

If the app can't access your location:
1. Go to **System Settings** → **Privacy & Security** → **Location Services**
2. Ensure Location Services is enabled
3. Find PuasaMenubar and set to "While Using"

### Build Errors

If you encounter build errors:
```bash
# Clean build
rm -rf .build
swift package resolve
swift build
```

### App Won't Launch

Try re-signing the app:
```bash
codesign --force --sign --entitlements PuasaMenubar/PuasaMenubar.entitlements PuasaMenubar.app
```

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Prayer times data provided by [Aladhan API](https://aladhan.com/)
- Built with SwiftUI for macOS
