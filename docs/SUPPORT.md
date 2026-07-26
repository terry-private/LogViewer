# Support policy

## Supported environment

| Component | Minimum | Notes |
| --- | --- | --- |
| iOS / iPadOS | 18.0 | The UI uses SwiftUI APIs introduced in iOS 18. |
| Xcode | 26.0 | Xcode 26 is the first stable Xcode release containing the Swift 6.2 toolchain and iOS 26 SDK used by the package. |
| Swift tools | 6.2 | Declared by `Package.swift`. |
| Swift language mode | 6 | Package targets compile in Swift 6 mode. |

The minimum versions are compatibility floors, not a promise to support only
the newest OS. The package should continue to build and run on every iOS and
iPadOS version from iOS 18 through the SDK version bundled with the supported
Xcode release.

## Platform scope

The current `LogViewer` product contains both the log store and its SwiftUI /
UIKit presentation. Its supported platforms are therefore:

- iOS
- iPadOS

The following platforms are not currently in the supported build matrix:

- macOS
- Mac Catalyst
- tvOS
- watchOS
- visionOS

Platform-neutral logging types and storage are planned to move into a separate
Core target. Platform support can be expanded after that separation without
making the UIKit presentation part of every consumer.

## Xcode policy

- Stable Xcode releases are the compatibility baseline.
- Beta Xcode builds may be used for early verification, but passing on a beta
  does not replace verification with the minimum supported stable Xcode.
- A pull request that intentionally raises a minimum version must update
  `Package.swift`, `README.md`, this document, and the verification matrix
  together.

## Intended use and production builds

LogViewer is a developer support tool intended primarily for debug, development,
TestFlight, and other internal builds.

The package does not currently remove itself from release builds. Applications
that link it into production are responsible for controlling access and
preventing secrets or personal information from being recorded. Redaction and
production-access controls are tracked separately in LV-011.

## Local verification

Run the complete local verification:

```bash
./Scripts/verify.sh
```

Override the test destination when the default iPhone 16 / iOS 18.0 Simulator
is not installed:

```bash
LOGVIEWER_TEST_DESTINATION='platform=iOS Simulator,name=<name>,OS=<version>' \
  ./Scripts/verify.sh
```

The script performs the following individual checks.

Inspect the package manifest:

```bash
swift package dump-package
```

Build the package for its minimum supported iOS deployment target:

```bash
xcodebuild \
  -scheme LogViewer \
  -destination 'generic/platform=iOS Simulator' \
  IPHONEOS_DEPLOYMENT_TARGET=18.0 \
  build
```

Run package tests on an installed iOS 18-or-newer Simulator:

```bash
xcodebuild \
  -scheme LogViewer \
  -destination 'platform=iOS Simulator,name=<simulator name>' \
  test
```

The concrete stable-Xcode test matrix and automated workflow are owned by
LV-002.
