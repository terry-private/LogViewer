import SwiftUI

struct BottomScrollButton: View {
    var action: () -> Void
    init(action: @escaping () -> Void) {
        self.action = action
    }
    var body: some View {
        if #available(iOS 26, *) {
            Button {
                action()
            } label: {
                Image(systemName: "chevron.down")
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(
                LogViewerLocalization.string(
                    .accessibilityScrollToBottom
                )
            )
            .accessibilityIdentifier(
                LogViewerAccessibilityIdentifier.scrollToBottom
            )
        } else {
            Button {
                action()
            } label: {
                Image(systemName: "chevron.down")
                    .padding()
                    .background {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                    .foregroundStyle(Color(uiColor: .label))
            }
            .accessibilityLabel(
                LogViewerLocalization.string(
                    .accessibilityScrollToBottom
                )
            )
            .accessibilityIdentifier(
                LogViewerAccessibilityIdentifier.scrollToBottom
            )
        }
    }
}

#Preview {
    BottomScrollButton {
        print("tap")
    }
}
