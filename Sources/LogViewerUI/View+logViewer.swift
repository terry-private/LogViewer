import LogViewerCore
import SwiftUI
import UIKit

public enum ShowTrigger {
    case shake
    case custom(Binding<Bool>)
}

/// LogViewerを呼び出し元の画面内または専用ウインドウへ表示する方法。
public enum LogViewerPresentationStyle: Equatable, Sendable {
    /// 呼び出し元Viewの上へ重ねて表示する。
    case overlay
    /// 呼び出し元Viewが属する場面の専用ウインドウへ表示する。
    case window
}

public extension View {
    @ViewBuilder
    func logViewer(
        on trigger: ShowTrigger,
        presentation: LogViewerPresentationStyle = .overlay,
        store: any LogStore = Logger.shared.store,
        privacyPolicy: LogPrivacyPolicy = .none,
        isTransparent: Bool = false
    ) -> some View {
        switch trigger {
        case .shake:
            modifier(
                ShakeLogViewModifier(
                    presentation: presentation,
                    store: store,
                    privacyPolicy: privacyPolicy,
                    isTransparent: isTransparent
                )
            )
        case .custom(let visible):
            modifier(
                CustomLogViewModifier(
                    visible: visible,
                    presentation: presentation,
                    store: store,
                    privacyPolicy: privacyPolicy,
                    isTransparent: isTransparent
                )
            )
        }
    }
}

struct CustomLogViewModifier: ViewModifier {
    @Binding var visible: Bool
    let presentation: LogViewerPresentationStyle
    let store: any LogStore
    let privacyPolicy: LogPrivacyPolicy
    let isTransparent: Bool

    func body(content: Content) -> some View {
        content.modifier(
            LogViewerPresentationModifier(
                visible: $visible,
                presentation: presentation,
                store: store,
                privacyPolicy: privacyPolicy,
                isTransparent: isTransparent
            )
        )
    }

    func makeLogView(dismiss: @escaping () -> Void) -> LogView {
        LogView(
            store: store,
            privacyPolicy: privacyPolicy,
            isTransparent: isTransparent,
            dismiss: dismiss
        )
    }
}

struct ShakeLogViewModifier: ViewModifier {
    @State var visible: Bool = false
    let presentation: LogViewerPresentationStyle
    let store: any LogStore
    let privacyPolicy: LogPrivacyPolicy
    let isTransparent: Bool

    func body(content: Content) -> some View {
        content
            .modifier(
                LogViewerPresentationModifier(
                    visible: $visible,
                    presentation: presentation,
                    store: store,
                    privacyPolicy: privacyPolicy,
                    isTransparent: isTransparent
                )
            )
            .background {
                LogViewerSceneShakeDetector { _ in
                    withAnimation {
                        visible = ShakePresentationReducer.visibility(
                            afterShakeWhileVisible: visible
                        )
                    }
                }
                .frame(width: 0, height: 0)
            }
    }

    func makeLogView(dismiss: @escaping () -> Void) -> LogView {
        LogView(
            store: store,
            privacyPolicy: privacyPolicy,
            isTransparent: isTransparent,
            dismiss: dismiss
        )
    }
}

private struct LogViewerPresentationModifier: ViewModifier {
    @Binding var visible: Bool
    let presentation: LogViewerPresentationStyle
    let store: any LogStore
    let privacyPolicy: LogPrivacyPolicy
    let isTransparent: Bool
    @State private var windowScene: UIWindowScene?
    @State private var windowPresenter = LogViewerWindowPresenter()

    @ViewBuilder
    func body(content: Content) -> some View {
        switch presentation {
        case .overlay:
            content.overlay {
                if visible {
                    makeLogView {
                        visible = false
                    }
                }
            }
        case .window:
            content
                .background {
                    LogViewerWindowSceneReader { scene in
                        sceneDidChange(scene)
                    }
                    .frame(width: 0, height: 0)
                }
                .onChange(of: visible, initial: true) {
                    updateWindowPresentation()
                }
                .onDisappear {
                    windowPresenter.dismiss()
                    windowScene = nil
                }
        }
    }

    private func makeLogView(
        dismiss: @escaping () -> Void
    ) -> LogView {
        LogView(
            store: store,
            privacyPolicy: privacyPolicy,
            isTransparent: isTransparent,
            dismiss: dismiss
        )
    }

    private func sceneDidChange(_ newScene: UIWindowScene?) {
        if windowScene !== newScene {
            windowPresenter.dismiss()
            windowScene = newScene
        }
        updateWindowPresentation()
    }

    private func updateWindowPresentation() {
        guard visible else {
            windowPresenter.dismiss()
            return
        }
        guard let windowScene else { return }

        let visibility = $visible
        let didPresent = windowPresenter.present(
            in: windowScene,
            store: store,
            privacyPolicy: privacyPolicy,
            isTransparent: isTransparent
        ) {
            visibility.wrappedValue = false
        }
        if !didPresent {
            visibility.wrappedValue = false
        }
    }
}
