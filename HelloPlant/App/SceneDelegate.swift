import CloudKit
import CoreData
import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        guard let sharedStore = AppServices.persistence.sharedStore else { return }
        AppServices.persistence.container.acceptShareInvitations(
            from: [metadata],
            into: sharedStore
        ) { _, error in
            if let error {
                NotificationCenter.default.post(
                    name: .plantStoreDidChange,
                    object: error
                )
                return
            }
            NotificationCenter.default.post(
                name: .plantStoreDidChange,
                object: nil
            )
        }
    }
}
