import Foundation

actor InMemoryPlantRepository: PlantRepository {
    private var storedHome: Home
    private var plants: [Plant]
    private var events: [WateringEvent]
    private var undoableEventID: UUID?

    init(
        home: Home = Home(id: UUID(), name: "Our Home", createdAt: .now),
        plants: [Plant]? = nil,
        events: [WateringEvent] = []
    ) {
        self.storedHome = home
        self.plants = plants ?? [
            Plant(id: UUID(), name: "Monstera", createdAt: .now, iconName: "leaf.fill"),
            Plant(id: UUID(), name: "Snake Plant", createdAt: .now.addingTimeInterval(1), iconName: "camera.macro"),
            Plant(id: UUID(), name: "Fiddle Leaf Fig", createdAt: .now.addingTimeInterval(2), iconName: "fan.fill")
        ]
        self.events = events
    }

    func home() async throws -> Home { storedHome }

    func plantStatuses(includeArchived: Bool) async throws -> [PlantStatus] {
        plants
            .filter { includeArchived || $0.archivedAt == nil }
            .map { plant in
                PlantStatus(plant: plant, wateringEvents: events.filter { $0.plantID == plant.id })
            }
            .sorted(by: PlantStatus.displayOrder)
    }

    func addPlant(named name: String, iconName: String?) async throws -> Plant {
        let name = try validated(name)
        let plant = Plant(id: UUID(), name: name, createdAt: .now, iconName: iconName)
        plants.append(plant)
        return plant
    }

    func renamePlant(id: UUID, to name: String, iconName: String?) async throws {
        guard let index = plants.firstIndex(where: { $0.id == id }) else {
            throw PlantRepositoryError.plantNotFound
        }
        plants[index].name = try validated(name)
        plants[index].iconName = iconName
    }

    func archivePlant(id: UUID) async throws {
        guard let index = plants.firstIndex(where: { $0.id == id }) else {
            throw PlantRepositoryError.plantNotFound
        }
        plants[index].archivedAt = .now
    }

    func restorePlant(id: UUID) async throws {
        guard let index = plants.firstIndex(where: { $0.id == id }) else {
            throw PlantRepositoryError.plantNotFound
        }
        plants[index].archivedAt = nil
    }

    func wateringHistory(plantID: UUID) async throws -> [WateringEvent] {
        guard plants.contains(where: { $0.id == plantID }) else {
            throw PlantRepositoryError.plantNotFound
        }
        return events
            .filter { $0.plantID == plantID }
            .sorted { $0.wateredAt > $1.wateredAt }
    }

    func recordWatering(plantID: UUID, by displayName: String, at date: Date) async throws -> WateringEvent {
        guard plants.contains(where: { $0.id == plantID }) else {
            throw PlantRepositoryError.plantNotFound
        }
        let event = WateringEvent(
            id: UUID(),
            wateredAt: date,
            wateredBy: displayName,
            createdAt: .now,
            plantID: plantID
        )
        events.append(event)
        undoableEventID = event.id
        return event
    }

    func undoWatering(eventID: UUID) async throws {
        guard undoableEventID == eventID,
              let index = events.firstIndex(where: { $0.id == eventID }) else {
            throw PlantRepositoryError.wateringNotUndoable
        }
        events.remove(at: index)
        undoableEventID = nil
    }

    private func validated(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlantRepositoryError.invalidName }
        return trimmed
    }
}
