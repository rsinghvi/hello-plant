import Foundation

extension CDHome {
    var domainModel: Home {
        Home(
            id: id ?? UUID(),
            name: name ?? String(localized: "Our Home"),
            createdAt: createdAt ?? .distantPast
        )
    }
}

extension CDPlant {
    var domainModel: Plant {
        Plant(
            id: id ?? UUID(),
            name: name ?? String(localized: "Unnamed plant"),
            createdAt: createdAt ?? .distantPast,
            archivedAt: archivedAt,
            iconName: iconName
        )
    }
}

extension CDWateringEvent {
    var domainModel: WateringEvent? {
        guard let plantID = plant?.id else { return nil }
        return WateringEvent(
            id: id ?? UUID(),
            wateredAt: wateredAt ?? .distantPast,
            wateredBy: wateredBy ?? String(localized: "Someone"),
            createdAt: createdAt ?? .distantPast,
            plantID: plantID
        )
    }
}
