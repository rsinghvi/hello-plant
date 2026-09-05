import Foundation

struct PlantStatus: Identifiable, Hashable, Sendable {
    let plant: Plant
    let wateringEvents: [WateringEvent]

    var id: UUID { plant.id }
    var lastEvent: WateringEvent? {
        wateringEvents.max { $0.wateredAt < $1.wateredAt }
    }

    init(plant: Plant, wateringEvents: [WateringEvent] = []) {
        self.plant = plant
        self.wateringEvents = wateringEvents
    }

    static func displayOrder(_ lhs: PlantStatus, _ rhs: PlantStatus) -> Bool {
        switch (lhs.lastEvent, rhs.lastEvent) {
        case (nil, nil):
            return lhs.plant.createdAt < rhs.plant.createdAt
        case (nil, _):
            return true
        case (_, nil):
            return false
        case let (left?, right?):
            return left.wateredAt < right.wateredAt
        }
    }
}
