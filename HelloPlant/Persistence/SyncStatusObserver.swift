import CoreData
import Foundation
import Observation

enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case error(String)
}

enum SyncEventResult: Equatable, Sendable {
    case started
    case succeeded
    case failed(String)
}

@MainActor
@Observable
final class SyncStatusObserver {
    private(set) var status: SyncStatus = .idle
    private var token: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default) {
        token = notificationCenter.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else {
                return
            }
            let result: SyncEventResult
            if event.endDate == nil {
                result = .started
            } else if let error = event.error {
                result = .failed(error.localizedDescription)
            } else {
                result = .succeeded
            }
            Task { @MainActor in self?.apply(result) }
        }
    }

    func apply(_ event: SyncEventResult) {
        switch event {
        case .started: status = .syncing
        case .succeeded: status = .idle
        case let .failed(message): status = .error(message)
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
