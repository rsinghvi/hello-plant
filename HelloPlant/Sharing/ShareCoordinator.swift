import CloudKit
import CoreData
import UIKit

enum SharingAccess: Sendable {
    case unshared
    case owner
    case participant
}

final class ShareCoordinator: @unchecked Sendable {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func sharingController(for homeID: NSManagedObjectID) async throws -> UICloudSharingController {
        if let share = try await existingShare(for: homeID) {
            return configuredController(
                share: share,
                container: CKContainer(identifier: PersistenceController.cloudContainerIdentifier)
            )
        }
        let (share, container) = try await makeShare(for: homeID)
        return configuredController(share: share, container: container)
    }

    func participantNames(for homeID: NSManagedObjectID) async throws -> [String] {
        guard let share = try await existingShare(for: homeID) else { return [] }
        return share.participants.compactMap { $0.userIdentity.nameComponents?.formatted() }
    }

    func access(for homeID: NSManagedObjectID) async throws -> SharingAccess {
        guard let share = try await existingShare(for: homeID) else { return .unshared }
        return share.currentUserParticipant?.role == .owner ? .owner : .participant
    }

    private func existingShare(for homeID: NSManagedObjectID) async throws -> CKShare? {
        try persistence.container.fetchShares(matching: [homeID])[homeID]
    }

    private func makeShare(for homeID: NSManagedObjectID) async throws -> (CKShare, CKContainer) {
        let context = persistence.container.viewContext
        let home = try context.existingObject(with: homeID)
        let title = (home as? CDHome)?.name ?? String(localized: "Our Home")

        return try await withCheckedThrowingContinuation { continuation in
            persistence.container.share([home], to: nil) { _, share, container, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let share, let container {
                    share[CKShare.SystemFieldKey.title] = title as CKRecordValue
                    continuation.resume(returning: (share, container))
                } else {
                    continuation.resume(throwing: PlantRepositoryError.homeUnavailable)
                }
            }
        }
    }

    private func configuredController(
        share: CKShare,
        container: CKContainer
    ) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }
}
