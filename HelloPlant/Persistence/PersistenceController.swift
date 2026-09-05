import CloudKit
import CoreData

final class PersistenceController: @unchecked Sendable {
    static let cloudContainerIdentifier = "iCloud.com.rahulsinghvi.HelloPlant"
    static let shared = PersistenceController()

    // TEMPORARY: flip to `true` once this app is signed with a paid Apple Developer
    // Program account (a free "Personal Team" cannot provision the iCloud/Push
    // capabilities CloudKit sync requires). While `false`, the app runs against a
    // single local store with no CloudKit involvement at all — no entitlements,
    // capabilities, or containers are needed. Remove the iCloud and Push
    // Notifications capabilities in Xcode's Signing & Capabilities tab to match.
    static let isCloudSyncAvailable = false

    let container: NSPersistentCloudKitContainer
    let isCloudKitEnabled: Bool
    private var remoteChangeToken: NSObjectProtocol?

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "HelloPlant")
        isCloudKitEnabled = !inMemory && Self.isCloudSyncAvailable

        if inMemory {
            let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        } else if Self.isCloudSyncAvailable {
            container.persistentStoreDescriptions = Self.cloudStoreDescriptions()
        } else {
            container.persistentStoreDescriptions = [Self.localOnlyStoreDescription()]
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unable to load the HelloPlant store: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        remoteChangeToken = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .plantStoreDidChange, object: nil)
        }
    }

    var sharedStore: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first {
            $0.url?.lastPathComponent == "Shared.sqlite"
        }
    }

    private static func localOnlyStoreDescription() -> NSPersistentStoreDescription {
        let directory = NSPersistentContainer.defaultDirectoryURL()
        let description = NSPersistentStoreDescription(url: directory.appendingPathComponent("Local.sqlite"))
        description.configuration = "Default"
        return description
    }

    private static func cloudStoreDescriptions() -> [NSPersistentStoreDescription] {
        let directory = NSPersistentContainer.defaultDirectoryURL()
        return [
            cloudDescription(url: directory.appendingPathComponent("Private.sqlite"), scope: .private),
            cloudDescription(url: directory.appendingPathComponent("Shared.sqlite"), scope: .shared)
        ]
    }

    private static func cloudDescription(
        url: URL,
        scope: CKDatabase.Scope
    ) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: url)
        description.configuration = "Default"
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudContainerIdentifier)
        options.databaseScope = scope
        description.cloudKitContainerOptions = options
        return description
    }

    deinit {
        if let remoteChangeToken {
            NotificationCenter.default.removeObserver(remoteChangeToken)
        }
    }
}

extension Notification.Name {
    static let plantStoreDidChange = Notification.Name("HelloPlantStoreDidChange")
}
