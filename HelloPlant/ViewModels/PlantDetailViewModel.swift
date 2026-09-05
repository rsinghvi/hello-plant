import Foundation
import Observation

@MainActor
@Observable
final class PlantDetailViewModel {
    private(set) var status: PlantStatus
    private(set) var history: [WateringEvent] = []
    private(set) var errorMessage: String?
    var isEditing = false

    let profile: LocalProfile
    private let repository: any PlantRepository

    init(status: PlantStatus, repository: any PlantRepository, profile: LocalProfile) {
        self.status = status
        self.repository = repository
        self.profile = profile
    }

    func load() async {
        do {
            history = try await repository.wateringHistory(plantID: status.id)
            if let refreshed = try await repository
                .plantStatuses(includeArchived: true)
                .first(where: { $0.id == status.id }) {
                status = refreshed
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func water() async {
        do {
            _ = try await repository.recordWatering(
                plantID: status.id,
                by: profile.displayName,
                at: .now
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(name: String, iconName: String?) async -> Bool {
        do {
            try await repository.renamePlant(id: status.id, to: name, iconName: iconName)
            isEditing = false
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func archive() async -> Bool {
        do {
            try await repository.archivePlant(id: status.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
