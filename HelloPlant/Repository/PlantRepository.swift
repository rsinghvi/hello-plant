import Foundation

enum PlantRepositoryError: LocalizedError, Equatable, Sendable {
    case homeUnavailable
    case plantNotFound
    case invalidName
    case wateringNotUndoable

    var errorDescription: String? {
        switch self {
        case .homeUnavailable: String(localized: "Your home could not be loaded.")
        case .plantNotFound: String(localized: "That plant could not be found.")
        case .invalidName: String(localized: "Enter a plant name.")
        case .wateringNotUndoable: String(localized: "That watering can no longer be undone.")
        }
    }
}

protocol PlantRepository: Sendable {
    func home() async throws -> Home
    func plantStatuses(includeArchived: Bool) async throws -> [PlantStatus]
    func addPlant(named name: String, iconName: String?) async throws -> Plant
    func renamePlant(id: UUID, to name: String, iconName: String?) async throws
    func archivePlant(id: UUID) async throws
    func restorePlant(id: UUID) async throws
    func wateringHistory(plantID: UUID) async throws -> [WateringEvent]
    func recordWatering(plantID: UUID, by displayName: String, at date: Date) async throws -> WateringEvent
    func undoWatering(eventID: UUID) async throws
}
