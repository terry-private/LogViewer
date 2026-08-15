import SwiftUI

enum LogViewerInitialFocusTarget: Equatable {
    case close
}

struct LogViewerSelectionPresentation: Equatable {
    let showsCheckmark: Bool
    let isAccessibilitySelected: Bool
}

struct LogViewerAdaptiveLayout: Equatable {
    let usesStackedHeader: Bool
    let usesScrollableFilter: Bool
}

enum LogViewerAccessibilityPolicy {
    static let initialFocusTarget = LogViewerInitialFocusTarget.close

    static func recordingActionKey(
        isRecordingEnabled: Bool
    ) -> LogViewerStringKey {
        isRecordingEnabled ? .recordingPause : .recordingResume
    }

    static func emptyStateKey(
        resultCount: Int,
        totalCount: Int,
        isFilterActive: Bool
    ) -> LogViewerStringKey? {
        guard resultCount == 0 else { return nil }
        if totalCount == 0 {
            return .emptyNoLogs
        }
        return isFilterActive ? .emptyNoMatches : .emptyNoLogs
    }

    static func selectionPresentation(
        isSelected: Bool
    ) -> LogViewerSelectionPresentation {
        LogViewerSelectionPresentation(
            showsCheckmark: isSelected,
            isAccessibilitySelected: isSelected
        )
    }

    static func adaptiveLayout(
        for dynamicTypeSize: DynamicTypeSize
    ) -> LogViewerAdaptiveLayout {
        let isAccessibilitySize = dynamicTypeSize.isAccessibilitySize
        return LogViewerAdaptiveLayout(
            usesStackedHeader: isAccessibilitySize,
            usesScrollableFilter: isAccessibilitySize
        )
    }
}

struct LogDeletionConfirmationState: Equatable {
    private(set) var isPresented = false

    mutating func request() {
        isPresented = true
    }

    mutating func cancel() {
        isPresented = false
    }

    mutating func confirm() -> Bool {
        guard isPresented else { return false }
        isPresented = false
        return true
    }
}
