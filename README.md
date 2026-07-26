# LogViewer

A beautiful and intuitive debug log viewer for SwiftUI applications.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018%2B-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/terry-private/LogViewer/blob/main/LICENSE)

## Features

- 🔍 **Real-time Log Display** - View logs instantly as they're generated
- 🏷️ **Dynamic Tag Filtering** - Automatically collects and displays all tags for easy filtering
- 📂 **Smart Organization** - Group logs by file or function
- 📱 **Shake to Open** - Access logs with a simple shake gesture
- ⏸️ **Pause/Resume** - Control log collection on the fly
- 🎨 **Beautiful UI** - Modern SwiftUI design with smooth animations
- 🔄 **Auto-scroll** - Automatically follows new logs with smart detection
- 🔎 **Search** - Full-text search across messages, files, and functions

## Requirements

- iOS 18.0+
- Xcode 26.0+
- Swift 6.2+

LogViewer currently supports SwiftUI apps running on iOS and iPadOS. macOS,
Mac Catalyst, tvOS, watchOS, and visionOS are not part of the supported build
matrix yet.

LogViewer is intended primarily for debug and internal builds. If you include
it in a production build, review the logs for credentials, personal data, and
other sensitive information before enabling the viewer.

See [Support Policy](docs/SUPPORT.md) for the complete compatibility policy and
local verification commands.

## Installation

### Swift Package Manager

Add LogViewer to your project through Xcode:

1. File → Add Package Dependencies...
2. Enter: `https://github.com/terry-private/LogViewer.git`
3. Select the `main` branch until the first stable version is released
4. Click "Add Package"

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/terry-private/LogViewer.git",
        branch: "main"
    )
]
```

## Quick Start

### 1. Import and Setup

```swift
import LogViewer
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .logViewer(on: .shake) // Enable shake gesture
        }
    }
}
```

### 2. Add Logs

```swift
import LogViewer

// Simple log
Logger.shared.add("User logged in")

// Log with tags
Logger.shared.add("API Response received", tags: "api", "network")

// Log errors
@MainActor
func report(_ error: any Error) {
    Logger.shared.add("Operation failed: \(error)", tags: "error")
}

// Multiple tags
Logger.shared.add("User profile updated", tags: "user", "api", "success")
```

### 3. Custom Trigger

```swift
struct ContentView: View {
    @State private var showLogs = false
    
    var body: some View {
        VStack {
            Button("Show Logs") {
                showLogs = true
            }
        }
        .logViewer(on: .custom($showLogs))
    }
}
```

## Advanced Usage

### Dynamic Tag Filtering

The log viewer now automatically collects all tags used in your app and provides a dynamic filtering interface:

```swift
// Add logs with various tags throughout your app
Logger.shared.add("Network request started", tags: "network")
Logger.shared.add("User authenticated", tags: "auth", "success")
Logger.shared.add("Cache miss", tags: "cache", "warning")

// The viewer will show all logs and let users filter by any of these tags
ContentView()
    .logViewer(on: .shake)
```

### Log with Context

Logs automatically capture file and function information:

```swift
// In UserService.swift
@MainActor
func fetchUser(id: String) {
    Logger.shared.add("Fetching user: \(id)", tags: "api", "user")
    // Logs: "Fetching user: 123" with file "UserService.swift" and function "fetchUser(id:)"
}
```

The current `Logger` API is isolated to `MainActor`. Call it from a
`@MainActor` context or explicitly switch to the main actor. Support for
recording directly from arbitrary tasks is tracked in
[Issue #7](https://github.com/terry-private/LogViewer/issues/7).

### Organize Logs

The viewer provides three view modes:
- **All**: Chronological list of all logs
- **File**: Grouped by source file
- **Function**: Grouped by function name

### Filtering Options

Within the log viewer, you can:
- **Filter by Tags**: Select from automatically collected tags
- **Search**: Find logs containing specific text

Search and tag filtering are currently separate modes. Composable filters are
planned for a future release.

## API Reference

### Logger

```swift
// Singleton instance
Logger.shared

// Add log with optional tags
func add(_ message: String, tags: Tag..., fileID: String = #fileID, function: String = #function)
```

### View Extension

```swift
// Enable log viewer
func logViewer(on trigger: ShowTrigger, isTransparent: Bool = false) -> some View
```

`isTransparent` controls the initial background style. The in-view menu can
change the style while the viewer is open.

If the importing application also uses `os.Logger`, qualify this package's
current logger as `LogViewer.Logger`. A less collision-prone logging API is
planned as part of the v1.0 model redesign.

### ShowTrigger

```swift
enum ShowTrigger {
    case shake                    // Shake device to show
    case custom(Binding<Bool>)   // Custom toggle binding
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

LogViewer is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Author

[terry-private](https://github.com/terry-private)
