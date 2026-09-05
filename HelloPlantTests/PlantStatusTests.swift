import Foundation
import Testing
@testable import HelloPlant

struct PlantStatusTests {
    private let plant = Plant(
        id: UUID(),
        name: "Monstera",
        createdAt: Date(timeIntervalSince1970: 100)
    )

    @Test func neverWateredHasNoLatestEvent() {
        let status = PlantStatus(plant: plant)
        #expect(status.lastEvent == nil)
        #expect(RelativeDateText.display(for: status.lastEvent?.wateredAt) == "Never watered")
    }

    @Test func newestDateWinsRegardlessOfInsertionOrder() {
        let old = event(at: 1_000)
        let newest = event(at: 3_000)
        let middle = event(at: 2_000)
        let status = PlantStatus(plant: plant, wateringEvents: [newest, old, middle])
        #expect(status.lastEvent?.id == newest.id)
    }

    @Test func neverWateredAndOldestWateredSortFirst() {
        let never = PlantStatus(plant: plant)
        let older = PlantStatus(
            plant: Plant(id: UUID(), name: "Older", createdAt: .now),
            wateringEvents: [event(at: 1_000)]
        )
        let newer = PlantStatus(
            plant: Plant(id: UUID(), name: "Newer", createdAt: .now),
            wateringEvents: [event(at: 2_000)]
        )
        let sorted = [newer, older, never].sorted(by: PlantStatus.displayOrder)
        #expect(sorted.map(\.id) == [never.id, older.id, newer.id])
    }

    @Test func accessibilityLabelsDescribeStatusAndPerson() {
        let now = Date(timeIntervalSince1970: 10_000)
        let never = PlantStatus(plant: plant)
        #expect(
            RelativeDateText.spoken(for: never, currentDisplayName: "Alex", now: now)
                == "Monstera, never watered"
        )

        let watered = PlantStatus(
            plant: plant,
            wateringEvents: [
                WateringEvent(
                    id: UUID(),
                    wateredAt: now.addingTimeInterval(-10),
                    wateredBy: "Alex",
                    createdAt: now,
                    plantID: plant.id
                )
            ]
        )
        #expect(
            RelativeDateText.spoken(for: watered, currentDisplayName: "Alex", now: now)
                == "Monstera, last watered just now by you"
        )
    }

    private func event(at timestamp: TimeInterval) -> WateringEvent {
        WateringEvent(
            id: UUID(),
            wateredAt: Date(timeIntervalSince1970: timestamp),
            wateredBy: "Alex",
            createdAt: .now,
            plantID: plant.id
        )
    }
}
