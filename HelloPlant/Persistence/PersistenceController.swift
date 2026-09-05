import CloudKit
import CoreData

final class PersistenceController: @unchecked Sendable {
    static let cloudContainerIdentifier = "iCloud.com.rahulsinghvi.HelloPlant"
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    let isCloudKitEnabled: Bool
    private var remoteChangeToken: NSObjectProtocol?

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "HelloPlant")
        isCloudKitEnabled = !inMemory

        if inMemory {
            let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        } else {
            container.persistentStoreDescriptions = Self.cloudStoreDescriptions()
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
