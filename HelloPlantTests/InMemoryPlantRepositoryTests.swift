import Foundation
import Testing
@testable import HelloPlant

struct InMemoryPlantRepositoryTests {
    @Test func repeatedWateringCreatesDistinctEvents() async throws {
        let plant = Plant(id: UUID(), name: "Fern", createdAt: .now)
        let repository = InMemoryPlantRepository(plants: [plant])

        let first = try await repository.recordWatering(plantID: plant.id, by: "Alex", at: .now)
        let second = try await repository.recordWatering(plantID: plant.id, by: "Alex", at: .now)

        #expect(first.id != second.id)
        #expect(try await repository.wateringHistory(plantID: plant.id).count == 2)
    }

    @Test func undoOnlyRemovesLatestLocallyRecordedEvent() async throws {
        let plant = Plant(id: UUID(), name: "Fern", createdAt: .now)
        let remoteEvent = WateringEvent(
            id: UUID(),
            wateredAt: .now.addingTimeInterval(-60),
            wateredBy: "Sam",
            createdAt: .now,
            plantID: plant.id
        )
        let repository = InMemoryPlantRepository(plants: [plant], events: [remoteEvent])
        let localEvent = try await repository.recordWatering(
            plantID: plant.id,
            by: "Alex",
            at: .now
        )

        await #expect(throws: PlantRepositoryError.wateringNotUndoable) {
            try await repository.undoWatering(eventID: remoteEvent.id)
        }
        try await repository.undoWatering(eventID: localEvent.id)
        #expect(try await repository.wateringHistory(plantID: plant.id).map(\.id) == [remoteEvent.id])
        await #expect(throws: PlantRepositoryError.wateringNotUndoable) {
            try await repository.undoWatering(eventID: localEvent.id)
        }
    }

    @Test func renameArchiveAndRestorePreserveHistory() async throws {
        let plant = Plant(id: UUID(), name: "Fern", createdAt: .now)
        let repository = InMemoryPlantRepository(plants: [plant])
        let event = try await repository.recordWatering(
            plantID: plant.id,
            by: "Alex",
            at: .now
        )

        try await repository.renamePlant(id: plant.id, to: "Boston Fern", iconName: "fan.fill")
        try await repository.archivePlant(id: plant.id)
        #expect(try await repository.plantStatuses(includeArchived: false).isEmpty)
        let archived = try await repository.plantStatuses(includeArchived: true).first
        #expect(archived?.plant.id == plant.id)
        #expect(archived?.plant.name == "Boston Fern")
        #expect(archived?.lastEvent?.id == event.id)

        try await repository.restorePlant(id: plant.id)
        #expect(try await repository.plantStatuses(includeArchived: false).count == 1)
    }
}
