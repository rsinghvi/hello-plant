import Observation
import UIKit

@MainActor
@Observable
final class AppEnvironment {
    let repository: any PlantRepository
    let profileStore: LocalProfileStore
    let syncObserver: SyncStatusObserver

    private let coreDataRepository: CoreDataPlantRepository
    private let shareCoordinator: ShareCoordinator

    init(persistence: PersistenceController = .shared) {
        let repository = CoreDataPlantRepository(persistence: persistence)
        self.coreDataRepository = repository
        self.repository = repository
        self.profileStore = LocalProfileStore()
        self.syncObserver = SyncStatusObserver()
        self.shareCoordinator = ShareCoordinator(persistence: persistence)
    }

    func sharingController() async throws -> UICloudSharingController {
        let homeID = try await coreDataRepository.homeManagedObjectID()
        return try await shareCoordinator.sharingController(for: homeID)
    }

    func participantNames() async throws -> [String] {
        let homeID = try await coreDataRepository.homeManagedObjectID()
        return try await shareCoordinator.participantNames(for: homeID)
    }

    func sharingAccess() async throws -> SharingAccess {
        let homeID = try await coreDataRepository.homeManagedObjectID()
        return try await shareCoordinator.access(for: homeID)
    }
}

enum AppServices {
    static let persistence = PersistenceController.shared
}
