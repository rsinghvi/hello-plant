import Foundation

nonisolated enum RelativeDateText {
    static func display(for date: Date?, now: Date = .now, calendar: Calendar = .current) -> String {
        guard let date else { return String(localized: "Never watered") }
        let elapsed = max(0, now.timeIntervalSince(date))
        if elapsed < 60 { return String(localized: "Just now") }
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(date: .omitted, time: .shortened)
                .withPrefix(String(localized: "Today"))
        }
        let days = max(1, calendar.dateComponents([.day], from: date, to: now).day ?? 1)
        if days == 1 { return String(localized: "1 day ago") }
        return String(localized: "\(days) days ago")
    }

    static func spoken(for status: PlantStatus, currentDisplayName: String, now: Date = .now) -> String {
        guard let event = status.lastEvent else {
            return String(localized: "\(status.plant.name), never watered")
        }
        let person = event.wateredBy == currentDisplayName ? String(localized: "you") : event.wateredBy
        let relative = display(for: event.wateredAt, now: now).lowercased()
        return String(localized: "\(status.plant.name), last watered \(relative) by \(person)")
    }
}

private extension String {
    func withPrefix(_ prefix: String) -> String {
        "\(prefix) \(self)"
    }
}
