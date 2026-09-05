import Foundation
import Observation

@MainActor
@Observable
final class PlantListViewModel {
    private(set) var home: Home?
    private(set) var statuses: [PlantStatus] = []
    private(set) var archivedStatuses: [PlantStatus] = []
    private(set) var lastLocalEventID: UUID?
    private(set) var recentlyWateredPlantID: UUID?
    private(set) var errorMessage: String?
    var isAddingPlant = false
    var isShowingArchived = false
    var isShowingShare = false

    let profile: LocalProfile
    let syncObserver: SyncStatusObserver

    private let repository: any PlantRepository
    private var undoExpirationTask: Task<Void, Never>?
    private var changeToken: NSObjectProtocol?

    init(
        repository: any PlantRepository,
        profile: LocalProfile,
        syncObserver: SyncStatusObserver
    ) {
        self.repository = repository
        self.profile = profile
        self.syncObserver = syncObserver
        changeToken = NotificationCenter.default.addObserver(
            forName: .plantStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let changedEventID = notification.object as? UUID
            Task { @MainActor in
                guard let self else { return }
                if let current = self.lastLocalEventID,
                   let changedEventID,
                   current != changedEventID {
                    self.undoExpirationTask?.cancel()
                    self.clearUndoState()
                }
                await self.load()
            }
        }
    }

    func load() async {
        do {
            async let loadedHome = repository.home()
            async let active = repository.plantStatuses(includeArchived: false)
            async let all = repository.plantStatuses(includeArchived: true)
            let (home, statuses, allStatuses) = try await (loadedHome, active, all)
            self.home = home
            if recentlyWateredPlantID == nil {
                self.statuses = statuses
            } else {
                self.statuses = preservingCurrentOrder(with: statuses)
            }
            archivedStatuses = allStatuses.filter { $0.plant.archivedAt != nil }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func water(_ status: PlantStatus, at date: Date = .now) async {
        do {
            let event = try await repository.recordWatering(
                plantID: status.id,
                by: profile.displayName,
                at: date
            )
            lastLocalEventID = event.id
            recentlyWateredPlantID = status.id
            await load()
            scheduleUndoExpiration()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoLastWatering() async {
        guard let eventID = lastLocalEventID else { return }
        undoExpirationTask?.cancel()
        do {
            try await repository.undoWatering(eventID: eventID)
            clearUndoState()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPlant(name: String, iconName: String?) async -> Bool {
        do {
            _ = try await repository.addPlant(named: name, iconName: iconName)
            isAddingPlant = false
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore(_ status: PlantStatus) async {
        do {
            try await repository.restorePlant(id: status.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func scheduleUndoExpiration() {
        undoExpirationTask?.cancel()
        undoExpirationTask = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            clearUndoState()
            await load()
        }
    }

    private func clearUndoState() {
        lastLocalEventID = nil
        recentlyWateredPlantID = nil
    }

    private func preservingCurrentOrder(with updated: [PlantStatus]) -> [PlantStatus] {
        let indexed = Dictionary(uniqueKeysWithValues: updated.map { ($0.id, $0) })
        let retained = statuses.compactMap { indexed[$0.id] }
        let retainedIDs = Set(retained.map(\.id))
        return retained + updated.filter { !retainedIDs.contains($0.id) }
    }

    deinit {
        undoExpirationTask?.cancel()
        if let changeToken {
            NotificationCenter.default.removeObserver(changeToken)
        }
    }
}
