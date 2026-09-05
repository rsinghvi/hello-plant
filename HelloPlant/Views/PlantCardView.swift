import SwiftUI

struct PlantCardView: View {
    let status: PlantStatus
    let currentDisplayName: String
    let isRecentlyWatered: Bool
    let detailAction: () -> Void
    let waterAction: () -> Void

    private var accent: PlantAccent { .accent(for: status.plant.iconName) }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent.color)
                .frame(width: 5)
                .padding(.vertical, -12)

            Button(action: detailAction) {
                HStack(spacing: 10) {
                    Image(systemName: status.plant.iconName ?? PlantIcon.defaultName)
                        .font(.title2)
                        .foregroundStyle(accent.color)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [accent.tint, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.plant.name)
                            .font(.headline)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(2)
                        ViewThatFits(in: .horizontal) {
                            statusRow
                            VStack(alignment: .leading, spacing: 3) {
                                Text(RelativeDateText.display(for: status.lastEvent?.wateredAt))
                                if let event = status.lastEvent {
                                    PersonChip(name: event.wateredBy, currentDisplayName: currentDisplayName)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(isRecentlyWatered ? Palette.leafDark : Palette.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                RelativeDateText.spoken(
                    for: status,
                    currentDisplayName: currentDisplayName
                )
            )
            .accessibilityHint("Shows watering history")

            Button(action: waterAction) {
                HStack(spacing: 4) {
                    Image(systemName: isRecentlyWatered ? "checkmark" : "drop.fill")
                    Text(isRecentlyWatered ? "Watered" : "Water")
                }
                .font(.caption.bold())
                .foregroundStyle(isRecentlyWatered ? Palette.leafDeep : .white)
                .padding(.horizontal, 11)
                .frame(minHeight: 44)
                .background(isRecentlyWatered ? AnyShapeStyle(Palette.sage) : AnyShapeStyle(Palette.actionGradient))
                .clipShape(Capsule())
                .shadow(
                    color: isRecentlyWatered ? .clear : Palette.leafDark.opacity(0.3),
                    radius: 5,
                    y: 3
                )
            }
            .buttonStyle(.plain)
            .disabled(isRecentlyWatered)
            .accessibilityLabel("Watered Now")
            .accessibilityHint("Records a watering by you")
        }
        .padding(12)
        .background(
            (isRecentlyWatered ? Palette.sageLight : Palette.paper)
                .overlay(accent.color.opacity(isRecentlyWatered ? 0 : 0.045))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Palette.leafDeep.opacity(0.09), radius: 7, y: 3)
    }

    private var statusRow: some View {
        HStack(spacing: 5) {
            Text(RelativeDateText.display(for: status.lastEvent?.wateredAt))
                .lineLimit(1)
            if let event = status.lastEvent {
                PersonChip(name: event.wateredBy, currentDisplayName: currentDisplayName)
            }
        }
    }
}
