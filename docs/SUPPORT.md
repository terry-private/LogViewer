# Support policy

## Supported environment

| Component | Minimum | Notes |
| --- | --- | --- |
| iOS / iPadOS | 18.0 | The UI uses SwiftUI APIs introduced in iOS 18. |
| Xcode | 26.0 | Policy baseline. Verification with the minimum stable Xcode is still pending. |
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

By default, the script selects one compatible iOS Simulator reported by the
LogViewer scheme. Override it when a specific runtime is required:

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

The minimum iOS version is verified by the generic build. Running tests on the
minimum iOS runtime requires installing that runtime and setting
`LOGVIEWER_TEST_DESTINATION` explicitly.

Verification with Xcode 26 stable and a future hosted CI workflow remain tracked
by [Issue #3](https://github.com/terry-private/LogViewer/issues/3). A successful
run on a beta toolchain is useful early feedback, but is not evidence that the
minimum stable toolchain has passed.
