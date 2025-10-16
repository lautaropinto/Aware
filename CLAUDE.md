# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Building the Project
- **Build for iOS Simulator**: Open `Aware.xcodeproj` in Xcode and use Cmd+B or Product > Build
- **Run on iOS Simulator**: Open `Aware.xcodeproj` in Xcode and use Cmd+R or Product > Run
- **Run Tests**: Use Cmd+U in Xcode or Product > Test
- **Build for Apple Watch**: Select the "AwareWatch Watch App" scheme in Xcode

### Testing
- **Unit Tests**: Located in `AwareTests/` directory
- **UI Tests**: Located in `AwareUITests/` directory
- Tests can be run individually by selecting specific test methods in Xcode

## Architecture Overview

This is a SwiftUI-based iOS and Apple Watch timer/time-tracking application with the following key architectural components:

### Core Data Layer (`AwareData` Package)
- **SwiftData Models**: Uses SwiftData for persistence with CloudKit integration
- **Tag Model** (`Tag.swift`): Represents activity categories with name, color, icon, and relationship to timers
- **Timekeeper Model** (`Timer.swift`): Core timer functionality with start/stop/pause/resume capabilities
- **SwiftDataContainer** (`SwiftDataContainer.swift`): Configures CloudKit private database ("iCloud.aware-timers")

### UI Layer (`AwareUI` Package)
- Shared UI components between iOS and watchOS apps
- `UnifiedTimerView`: Main timer display component
- `TimerButtons`: Timer control interface
- `BackgroundGradient`: Dynamic background theming based on active timer's tag color

### iOS App (`Aware/`)
- **Scenes Architecture**: 
  - `HomeScene`: Main timer interface with quick-start functionality
  - `HistoryScene`: Timer history and analytics
  - `TagForm`: Tag creation and editing
  - `OnboardingFlow`: First-time user experience
- **Navigation**: Tab-based navigation between Home and History
- **Dynamic Theming**: Background color changes based on active timer's tag

### Apple Watch App (`AwareWatchApp/`)
- Simplified timer interface optimized for watchOS
- Shared data models with iOS app via CloudKit sync
- Independent onboarding flow for watch-specific features

### Key Relationships
- **Tags ↔ Timekeepers**: Many-to-many relationship (though currently one tag per timer in practice)
- **CloudKit Sync**: Automatic sync between iOS and watchOS via private CloudKit database
- **SwiftUI Environment**: Shared app configuration for theming across components

### Development Patterns
- Uses SwiftData `@Query` for reactive data binding
- Environment-based configuration sharing (`CrossConfig`)
- Modular package structure for code reuse between platforms
- Preview-friendly architecture with in-memory model containers for SwiftUI previews

### Settings Architecture (`Aware/Scenes/Settings/`)
- **Modular Section Pattern**: Settings are organized as separate SwiftUI views for each functional area
- **File Structure**:
  - `SettingsScene.swift`: Main settings container with List of sections
  - `SettingsButton.swift`: Settings gear button with sheet presentation
  - Section directories: `Contact/`, `About/`, `RateApp/` etc.
- **Visual Design System**:
  - Uses `ColorfulIcon` label style with `.accent` color for consistency
  - Section items have `Color.gray.opacity(0.1)` background
  - External links show arrow indicator (`arrow.up.right`)
  - HStack layout: Label, Spacer, optional arrow icon
- **Integration Pattern**: Each section implements `View` protocol and gets added to `SettingsScene` List  

## Important Implementation Notes

- The app requires iOS 18+ and watchOS 11+ (see platform requirements in Package.swift files)
- CloudKit integration requires proper entitlements and iCloud container configuration
- Timer state is managed through SwiftData persistence, not in-memory state
- Color theming is hex-string based with SwiftUI Color extensions for conversion
