import SwiftUI

struct UndoBanner: View {
    let plantName: String
    let displayName: String
    let undoAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(plantName) watered", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                Text("Recorded as \(displayName)")
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x9DBFA6))
            }
            Spacer()
            Button("Undo", action: undoAction)
                .font(.subheadline.bold())
                .foregroundStyle(Color(hex: 0x8FE3A6))
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x24402A), Color(hex: 0x16281A)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }
}
