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

## SwiftUI Architecture Guidelines

### System Overview
A layered architecture for SwiftUI applications emphasizing simplicity, clarity, and maintainability. 
This architecture uses explicit state management, pure functional transformations, and minimal abstraction.

#### Core Principles

- **Directness over indirection** - Use the simplest solution that works
- **Pure functions for transformations** - All data processing is stateless
- **Observable state management** - State changes trigger UI updates automatically
- **Single source of truth** - Each piece of state has one owner
- **Explicit dependencies** - No hidden coupling or magic
- **Domain-driven organization** - Group by feature/domain, not layer
- **Minimal abstraction** - Add complexity only when needed, not preemptively


#### Architecture Layers

##### Layer 1: Storage (Data Persistence)
**Purpose:** Interface to persistence layer (SwiftData, Core Data, etc.)

Characteristics:

- Singleton instance with environment injection
- Observable for change notifications
- CRUD operations only, zero business logic
- Configured at app launch with persistence context

Implementation Pattern:

```
@Observable
final class Storage {
    static let shared = Storage()
    private var _context: ModelContext!
    private(set) var changeToken = UUID() // For triggering updates
    
    private init() {}
    
    func configure(context: ModelContext) {
        guard _context == nil else { fatalError("Storage already configured") }
        _context = context
    }
    
    func fetchAll<T: PersistentModel>(_ type: T.Type) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? _context.fetch(descriptor)) ?? []
    }
    
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        return (try? _context.fetch(descriptor)) ?? []
    }
    
    func insert<T: PersistentModel>(_ model: T) {
        _context.insert(model)
    }
    
    func delete<T: PersistentModel>(_ model: T) {
        _context.delete(model)
    }
    
    func save() {
        try? _context.save()
        changeToken = UUID()
    }
}
```

**Rules:**
✅ Simple CRUD operations
✅ Change notification mechanism
✅ Type-safe generic methods
❌ NO business logic
❌ NO data transformation
❌ NO complex queries (use fetch descriptors)

##### Layer 2: Managers (Cross-Cutting Business Logic)
**Purpose:** Handle app-wide concerns that span multiple features

When to use:
- State shared across unrelated features
- Integration with system services (notifications, widgets, etc.)
- Lifecycle management (sessions, timers, network state)
- Global configuration

Characteristics:
- Singleton pattern with environment injection
- Observable state
- Orchestrates multiple subsystems
- Contains side effects

Rules:
✅ App-wide state and logic
✅ Side effects (persistence, notifications, external APIs)
✅ Orchestration of multiple systems
✅ Singleton for truly global state
❌ NO view-specific logic
❌ NO data transformation (delegate to Processors)

##### Layer 3: Stores (Feature-Specific State)

**Purpose:** Manage state and orchestration for a specific feature or domain. Example History observable class.

When to use: 
- Feature has UI-specific state (filters, selections, sort order)
- Feature needs processed/computed data from Storage
- Multiple views in the feature need shared state

Characteristics:
- Created per-instance by parent view
- Shared to child views via environment
- Observable state
- Orchestrates Processors and Storage
- No side effects beyond its domain

Rules:
✅ Domain/feature-specific state
✅ Orchestration of data flow
✅ UI state management (filters, selections)
✅ Instance per parent view (not singleton)
❌ NO data transformation logic (use Processors)
❌ NO cross-feature state (use Managers)
❌ NO direct external API calls

##### Layer 4: Processors (Pure Functions)
**Purpose:** Transform and compute data without side effects

When to use:
- Filtering collections
- Grouping/sorting data
- Calculations and aggregations
- Formatting for display
- Any stateless data transformation

Characteristics:
- Static functions in enums (never instantiated)
- Pure functions: same input always produces same output
- No dependencies on external state
- No side effects
- Composable and reusable

Rules:
✅ Pure functions only (input → output)
✅ Static methods in enums
✅ Compose small functions into larger ones
✅ Reusable across multiple Stores
❌ NO instance state
❌ NO side effects
❌ NO external dependencies
❌ NO Storage/Manager access

##### Layer 5: Views (Presentation)
**Purpose:** Render UI and handle user interactions

Characteristics:
- Declarative SwiftUI components
- Read state from environment
- Trigger actions on Stores/Managers
- Parent views create Stores, children consume them
- No business logic

Rules:
✅ Read state from environment
✅ Trigger actions via method calls
✅ Parent creates Store, children consume
✅ Keep views small and focused
❌ NO business logic
❌ NO data transformation
❌ NO direct Storage access
❌ NO @Query usage (use Store.refresh() pattern)

##### Dependency Management
Singleton Pattern with Environment

All singletons are also injectable via environment for testing and previews:

// Parent view creates Store
struct FeatureScene: View {
    @State private var store = FeatureStore()
    
    var body: some View {
        FeatureContent()
            .environment(store) // Share via environment
    }
}

// Children access via environment
struct ChildView: View {
    @Environment(FeatureStore.self) private var store
    // use store
}
```

### Decision Tree

**"Where does this code belong?"**

1. **Is it a CRUD operation on persisted data?**
   - YES → Storage layer

2. **Is it data transformation with no side effects?**
   - YES → Processor (pure function)

3. **Is it app-wide state affecting multiple unrelated features?**
   - YES → Manager (singleton)

4. **Is it feature-specific state or orchestration?**
   - YES → Store (per-instance)

5. **Is it rendering or user interaction?**
   - YES → View

**"Should this be a singleton?"**
- App-wide state that's genuinely global → YES (Manager, Storage)
- Feature-specific state → NO (Store, created by parent view)
- Stateless transformations → N/A (Processor, static functions)

**"Should I add a protocol for testability?"**
- Only if you're actively writing tests that need it
- Not "just in case"
- Prefer concrete types with simple initialization

### File Organization
```
App/
  - AppName.swift (main app entry)
  - AppDelegate.swift (if needed)

Core/
  Storage/
    - Storage.swift
  Managers/
    - SessionManager.swift
    - NotificationManager.swift
    - AppConfig.swift

Models/
  - Model1.swift
  - Model2.swift
  - SharedTypes.swift

Features/
  FeatureName/
    - FeatureStore.swift
    - FeatureProcessor.swift
    - FeatureScene.swift
    - Components/
      - FeatureList.swift
      - FeatureDetail.swift
      - FeatureFilter.swift

Shared/
  Components/
    - ReusableView1.swift
    - ReusableView2.swift
  Extensions/
    - Date+Extensions.swift
    - Color+Extensions.swift

Summary Checklist
When implementing a new feature, ask:

 Do I need persistent data? → Use Storage
 Do I need data transformation? → Create Processor functions
 Is this app-wide state? → Create Manager
 Is this feature-specific state? → Create Store
 Are my views just rendering? → Good
 Are my Processors pure functions? → Good
 Am I avoiding premature abstraction? → Good
 Can I test this easily? → If not, refactor

This architecture scales from small apps to large codebases while maintaining clarity and simplicity.
