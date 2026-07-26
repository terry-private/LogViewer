import LogViewerCore
import SwiftUI

public enum ShowTrigger {
    case shake
    case custom(Binding<Bool>)
}

public extension View {
    @ViewBuilder
    func logViewer(
        on trigger: ShowTrigger,
        store: any LogStore = Logger.shared.store,
        isTransparent: Bool = false
    ) -> some View {
        switch trigger {
        case .shake:
            modifier(
                ShakeLogViewModifier(
                    store: store,
                    isTransparent: isTransparent
                )
            )
        case .custom(let visible):
            modifier(
                CustomLogViewModifier(
                    visible: visible,
                    store: store,
                    isTransparent: isTransparent
                )
            )
        }
    }
}

struct CustomLogViewModifier: ViewModifier {
    @Binding var visible: Bool
    let store: any LogStore
    let isTransparent: Bool
    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    makeLogView {
                        visible = false
                    }
                }
            }
    }

    func makeLogView(dismiss: @escaping () -> Void) -> LogView {
        LogView(
            store: store,
            isTransparent: isTransparent,
            dismiss: dismiss
        )
    }
}

struct ShakeLogViewModifier: ViewModifier {
    @State var visible: Bool = false
    let store: any LogStore
    let isTransparent: Bool
    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    makeLogView {
                        visible = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                withAnimation {
                    visible.toggle()
                }
            }
    }

    func makeLogView(dismiss: @escaping () -> Void) -> LogView {
        LogView(
            store: store,
            isTransparent: isTransparent,
            dismiss: dismiss
        )
    }
}

extension NSNotification.Name {
    public static let deviceDidShakeNotification = NSNotification.Name("DeviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        NotificationCenter.default.post(name: .deviceDidShakeNotification, object: event)
    }
}
