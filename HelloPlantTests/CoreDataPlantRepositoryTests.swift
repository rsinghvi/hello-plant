import CoreData
import Foundation
import Testing
@testable import HelloPlant

@MainActor
struct CoreDataPlantRepositoryTests {
    @Test func inMemoryConfigurationNeverEnablesCloudKit() {
        let persistence = PersistenceController(inMemory: true)
        #expect(!persistence.isCloudKitEnabled)
        #expect(
            persistence.container.persistentStoreDescriptions
                .allSatisfy { $0.cloudKitContainerOptions == nil }
        )
    }

    @Test func createsOneHomeAndPersistsPlantEventAndArchive() async throws {
        let persistence = PersistenceController(inMemory: true)
        let repository = CoreDataPlantRepository(persistence: persistence)
        async let first = repository.home()
        async let secondHomeCall = repository.home()
        async let third = repository.plantStatuses(includeArchived: false)
        let (firstHome, secondHome, _) = try await (first, secondHomeCall, third)
        #expect(firstHome.id == secondHome.id)
        let homeCount = try persistence.container.viewContext.count(for: CDHome.fetchRequest())
        #expect(homeCount == 1)

        let plant = try await repository.addPlant(named: "Fern", iconName: "fan.fill")
        let firstEvent = try await repository.recordWatering(
            plantID: plant.id,
            by: "Alex",
            at: Date(timeIntervalSince1970: 1_000)
        )
        let second = try await repository.recordWatering(
            plantID: plant.id,
            by: "Sam",
            at: Date(timeIntervalSince1970: 2_000)
        )
        #expect(firstEvent.id != second.id)
        #expect(try await repository.plantStatuses(includeArchived: false)[0].lastEvent?.id == second.id)

        try await repository.undoWatering(eventID: second.id)
        #expect(try await repository.wateringHistory(plantID: plant.id).map(\.id) == [firstEvent.id])

        try await repository.renamePlant(id: plant.id, to: "Boston Fern", iconName: "fan.fill")
        try await repository.archivePlant(id: plant.id)
        #expect(try await repository.plantStatuses(includeArchived: false).isEmpty)
        let archived = try await repository.plantStatuses(includeArchived: true)[0]
        #expect(archived.plant.name == "Boston Fern")
        #expect(archived.lastEvent?.id == firstEvent.id)
    }
}
