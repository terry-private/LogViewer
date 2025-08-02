import SwiftUI

public enum ShowTrigger {
    case shake
    case custom(Binding<Bool>)
}

public extension View {
    @ViewBuilder
    func logViewer(on trigger: ShowTrigger, tags: Tag...) -> some View {
        switch trigger {
        case .shake:
            modifier(ShakeLogViewModifier())
        case .custom(let visible):
            modifier(CustomLogViewModifier(visible: visible))
        }
    }
}

struct CustomLogViewModifier: ViewModifier {
    @Binding var visible: Bool
    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    LogView() {
                        visible = false
                    }
                }
            }
    }
}

struct ShakeLogViewModifier: ViewModifier {
    @State var visible: Bool = false
    func body(content: Content) -> some View {
        content
            .overlay {
                if visible {
                    LogView() {
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
