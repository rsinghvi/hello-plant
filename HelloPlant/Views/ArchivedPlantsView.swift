import SwiftUI

struct ArchivedPlantsView: View {
    @Environment(\.dismiss) private var dismiss
    let statuses: [PlantStatus]
    let restore: (PlantStatus) async -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                BotanicalBackground()
                if statuses.isEmpty {
                    ContentUnavailableView(
                        "No archived plants",
                        systemImage: "archivebox",
                        description: Text("Plants you archive will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(statuses) { status in
                                archivedCard(status)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Archived")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(Palette.leafDark)
    }

    private func archivedCard(_ status: PlantStatus) -> some View {
        HStack(spacing: 12) {
            Image(systemName: status.plant.iconName ?? PlantIcon.defaultName)
                .font(.title2)
                .foregroundStyle(Palette.inkTertiary)
                .frame(width: 48, height: 48)
                .background(Color(hex: 0xEFF1ED))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading) {
                Text(status.plant.name)
                    .font(.headline)
                Text("\(status.wateringEvents.count) waterings")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            Button("Restore") {
                Task { await restore(status) }
            }
            .font(.caption.bold())
            .foregroundStyle(Palette.leafDark)
            .frame(minHeight: 44)
        }
        .foregroundStyle(Palette.inkTertiary)
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
