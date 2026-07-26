import SwiftUI

struct CloseButton: View {
    var action: () -> Void
    init(action: @escaping () -> Void) {
        self.action = action
    }
    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .close) {
                action()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.glass)
        } else {
            Button {
                action()
            } label: {
                Image(systemName: "xmark")
                    .padding()
                    .background {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                    .foregroundStyle(Color(uiColor: .label))
            }
        }
    }
}
