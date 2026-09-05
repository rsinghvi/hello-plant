import SwiftUI

struct HomeHeaderView: View {
    let displayName: String
    let statuses: [PlantStatus]
    let participantNames: [String]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let salutation = switch hour {
        case 5..<12: String(localized: "Good morning")
        case 12..<18: String(localized: "Good afternoon")
        default: String(localized: "Good evening")
        }
        return "\(salutation), \(displayName)"
    }

    private var summary: String {
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let watered = statuses.filter { ($0.lastEvent?.wateredAt ?? .distantPast) >= weekAgo }.count
        return String(localized: "\(statuses.count) plants · \(watered) watered this week")
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OUR HOME")
                    .font(.caption2.bold())
                    .tracking(1.3)
                    .foregroundStyle(Palette.leafDark)
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(Palette.ink)
                if !statuses.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            Spacer(minLength: 12)
            HStack(spacing: -9) {
                ParticipantAvatar(name: displayName, color: Palette.leaf)
                ForEach(
                    Array(participantNames.filter { $0 != displayName }.prefix(2).enumerated()),
                    id: \.offset
                ) { participant in
                    ParticipantAvatar(
                        name: participant.element,
                        color: participant.offset == 0 ? Palette.sky : Palette.lilac
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct ParticipantAvatar: View {
    let name: String
    let color: Color

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(color.gradient)
            .clipShape(Circle())
            .overlay(Circle().stroke(Palette.cream, lineWidth: 2))
            .accessibilityLabel(name)
    }
}
