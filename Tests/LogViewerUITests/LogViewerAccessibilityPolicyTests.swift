import SwiftUI
import Testing
@testable import LogViewerUI

@Suite("LogViewerのアクセシビリティ方針")
struct LogViewerAccessibilityPolicyTests {
    @Test("表示直後は閉じる操作を焦点対象にする")
    func focusesCloseControlInitially() {
        #expect(LogViewerAccessibilityPolicy.initialFocusTarget == .close)
    }

    @Test("記録状態から停止と再開の操作を選ぶ")
    func selectsRecordingAction() {
        #expect(LogViewerAccessibilityPolicy.recordingActionKey(
            isRecordingEnabled: true
        ) == .recordingPause)
        #expect(LogViewerAccessibilityPolicy.recordingActionKey(
            isRecordingEnabled: false
        ) == .recordingResume)
    }

    @Test("ログ件数と絞り込み状態から空表示を選ぶ")
    func selectsEmptyState() {
        #expect(LogViewerAccessibilityPolicy.emptyStateKey(
            resultCount: 0,
            totalCount: 0,
            isFilterActive: false
        ) == .emptyNoLogs)
        #expect(LogViewerAccessibilityPolicy.emptyStateKey(
            resultCount: 0,
            totalCount: 3,
            isFilterActive: true
        ) == .emptyNoMatches)
        #expect(LogViewerAccessibilityPolicy.emptyStateKey(
            resultCount: 1,
            totalCount: 3,
            isFilterActive: true
        ) == nil)
    }

    @Test("選択状態をチェック印とVoiceOver特性の両方へ反映する")
    func presentsSelectionWithoutRelyingOnColor() {
        #expect(LogViewerAccessibilityPolicy.selectionPresentation(
            isSelected: true
        ) == LogViewerSelectionPresentation(
            showsCheckmark: true,
            isAccessibilitySelected: true
        ))
        #expect(LogViewerAccessibilityPolicy.selectionPresentation(
            isSelected: false
        ) == LogViewerSelectionPresentation(
            showsCheckmark: false,
            isAccessibilitySelected: false
        ))
    }

    @Test("アクセシビリティ文字サイズで重要操作を可変配置する")
    func adaptsLayoutForAccessibilitySizes() {
        #expect(LogViewerAccessibilityPolicy.adaptiveLayout(
            for: .large
        ) == LogViewerAdaptiveLayout(
            usesStackedHeader: false,
            usesScrollableFilter: false
        ))
        #expect(LogViewerAccessibilityPolicy.adaptiveLayout(
            for: .accessibility5
        ) == LogViewerAdaptiveLayout(
            usesStackedHeader: true,
            usesScrollableFilter: true
        ))
    }

    @Test("削除は要求と確認を経て、キャンセルでは確定しない")
    func confirmsDeletionExplicitly() {
        var state = LogDeletionConfirmationState()

        #expect(!state.isPresented)
        let confirmationWithoutRequest = state.confirm()
        #expect(!confirmationWithoutRequest)

        state.request()
        #expect(state.isPresented)
        state.cancel()
        #expect(!state.isPresented)
        let confirmationAfterCancellation = state.confirm()
        #expect(!confirmationAfterCancellation)

        state.request()
        let confirmationAfterRequest = state.confirm()
        #expect(confirmationAfterRequest)
        #expect(!state.isPresented)
    }
}
