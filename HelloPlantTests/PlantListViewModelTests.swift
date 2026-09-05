import Foundation
import Testing
@testable import HelloPlant

@MainActor
struct PlantListViewModelTests {
    @Test func wateringRefreshesStatusAndTracksLocalEvent() async throws {
        let plant = Plant(id: UUID(), name: "Fern", createdAt: .now)
        let repository = InMemoryPlantRepository(plants: [plant])
        let model = PlantListViewModel(
            repository: repository,
            profile: LocalProfile(displayName: "Alex", installationIdentifier: UUID()),
            syncObserver: SyncStatusObserver()
        )
        await model.load()

        await model.water(model.statuses[0])

        #expect(model.lastLocalEventID != nil)
        #expect(model.recentlyWateredPlantID == plant.id)
        #expect(model.statuses[0].lastEvent?.wateredBy == "Alex")
    }

    @Test func syncStatusDoesNotDisableLocalWatering() async {
        let plant = Plant(id: UUID(), name: "Fern", createdAt: .now)
        let repository = InMemoryPlantRepository(plants: [plant])
        let sync = SyncStatusObserver()
        sync.apply(.failed("Offline"))
        let model = PlantListViewModel(
            repository: repository,
            profile: LocalProfile(displayName: "Alex", installationIdentifier: UUID()),
            syncObserver: sync
        )
        await model.load()
        await model.water(model.statuses[0])

        #expect(model.statuses[0].lastEvent != nil)
        #expect(sync.status == .error("Offline"))
    }
}
