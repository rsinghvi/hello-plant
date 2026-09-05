import SwiftUI

struct PersonChip: View {
    let name: String
    let currentDisplayName: String

    private var isCurrentUser: Bool { name == currentDisplayName }
    private var shownName: String { isCurrentUser ? String(localized: "you") : name }

    var body: some View {
        HStack(spacing: 4) {
            Text(String(name.prefix(1)).uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(isCurrentUser ? Palette.actionGradient : LinearGradient(
                    colors: [Palette.sky, Color(hex: 0x3D7FA8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .clipShape(Circle())
            Text(shownName)
                .font(.caption.bold())
                .foregroundStyle(isCurrentUser ? Palette.leafDeep : Color(hex: 0x2E6C93))
                .lineLimit(1)
        }
        .padding(.trailing, 7)
        .padding(.leading, 2)
        .padding(.vertical, 2)
        .background(isCurrentUser ? Palette.sageLight : Color(hex: 0xE7F2FA))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shownName)
    }
}
