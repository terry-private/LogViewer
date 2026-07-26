import SwiftUI

struct SectionHeader: View {
    var title: String
    var isOpen: Bool
    var body: some View {
        if #available(iOS 26, *) {
            content
                .glassEffect()
        } else {
            content
                .background(
                    Color(uiColor: .secondarySystemBackground)
                        .opacity(0.5)
                        .padding(.horizontal, -20)
                )
        }
    }

    var content: some View {
        HStack {
            Text(title)
                .multilineTextAlignment(.leading)
            Spacer()
            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(isOpen ? 90 : 0))
        }
        .foregroundStyle(Color(uiColor: .label))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
