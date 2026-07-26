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
        }
    }
}

#Preview {
    BottomScrollButton {
        print("tap")
    }
}
