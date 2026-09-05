import CoreData
import Foundation

actor CoreDataPlantRepository: PlantRepository {
    private let persistence: PersistenceController
    private var undoableEventID: UUID?
    private var homeResolutionTask: Task<NSManagedObjectID, Error>?

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func home() async throws -> Home {
        let homeID = try await resolvedHomeID()
        let context = backgroundContext()
        return try await context.perform {
            guard let home = try context.existingObject(with: homeID) as? CDHome else {
                throw PlantRepositoryError.homeUnavailable
            }
            return home.domainModel
        }
    }

    func plantStatuses(includeArchived: Bool) async throws -> [PlantStatus] {
        let homeID = try await resolvedHomeID()
        let context = backgroundContext()
        return try await context.perform {
            guard let home = try context.existingObject(with: homeID) as? CDHome else {
                throw PlantRepositoryError.homeUnavailable
            }
            let plants = (home.plants ?? [])
                .filter { includeArchived || $0.archivedAt == nil }
            return plants.map { plant in
                PlantStatus(
                    plant: plant.domainModel,
                    wateringEvents: (plant.wateringEvents ?? []).compactMap(\.domainModel)
                )
            }
            .sorted(by: PlantStatus.displayOrder)
        }
    }

    func addPlant(named name: String, iconName: String?) async throws -> Plant {
        let name = try Self.validated(name)
        let homeID = try await resolvedHomeID()
        let context = backgroundContext()
        let plant = try await context.perform {
            guard let home = try context.existingObject(with: homeID) as? CDHome else {
                throw PlantRepositoryError.homeUnavailable
            }
            let plant = CDPlant(context: context)
            plant.id = UUID()
            plant.name = name
            plant.iconName = iconName
            plant.createdAt = .now
            plant.home = home
            Self.assign(plant, with: home, in: context)
            try context.save()
            return plant.domainModel
        }
        postChange()
        return plant
    }

    func renamePlant(id: UUID, to name: String, iconName: String?) async throws {
        let name = try Self.validated(name)
        try await updatePlant(id: id) { plant in
            plant.name = name
            plant.iconName = iconName
        }
    }

    func archivePlant(id: UUID) async throws {
        try await updatePlant(id: id) { $0.archivedAt = .now }
    }

    func restorePlant(id: UUID) async throws {
        try await updatePlant(id: id) { $0.archivedAt = nil }
    }

    func wateringHistory(plantID: UUID) async throws -> [WateringEvent] {
        let context = backgroundContext()
        return try await context.perform {
            let plant = try Self.fetchPlant(id: plantID, in: context)
            return (plant.wateringEvents ?? [])
                .compactMap(\.domainModel)
                .sorted { $0.wateredAt > $1.wateredAt }
        }
    }

    func recordWatering(plantID: UUID, by displayName: String, at date: Date) async throws -> WateringEvent {
        let context = backgroundContext()
        let event = try await context.perform {
            let plant = try Self.fetchPlant(id: plantID, in: context)
            let event = CDWateringEvent(context: context)
            event.id = UUID()
            event.wateredAt = date
            event.wateredBy = displayName
            event.createdAt = .now
            event.plant = plant
            if let home = plant.home {
                Self.assign(event, with: home, in: context)
            }
            try context.save()
            guard let model = event.domainModel else {
                throw PlantRepositoryError.plantNotFound
            }
            return model
        }
        undoableEventID = event.id
        postChange(eventID: event.id)
        return event
    }

    func undoWatering(eventID: UUID) async throws {
        guard undoableEventID == eventID else {
            throw PlantRepositoryError.wateringNotUndoable
        }
        let context = backgroundContext()
        try await context.perform {
            let request = CDWateringEvent.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", eventID as CVarArg)
            guard let event = try context.fetch(request).first else {
                throw PlantRepositoryError.wateringNotUndoable
            }
            context.delete(event)
            try context.save()
        }
        undoableEventID = nil
        postChange(eventID: eventID)
    }

    func homeManagedObjectID() async throws -> NSManagedObjectID {
        try await resolvedHomeID()
    }

    private func resolvedHomeID() async throws -> NSManagedObjectID {
        if let sharedStore = persistence.sharedStore {
            let context = backgroundContext()
            if let sharedID = try await context.perform({
                try Self.fetchHome(in: context, stores: [sharedStore])?.objectID
            }) {
                return sharedID
            }
        }
        if let homeResolutionTask {
            return try await homeResolutionTask.value
        }

        let persistence = persistence
        let task = Task {
            let context = persistence.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return try await context.perform {
                let home = try Self.resolveHome(
                    in: context,
                    persistence: persistence,
                    createIfMissing: true
                )
                if home.objectID.isTemporaryID {
                    try context.obtainPermanentIDs(for: [home])
                }
                return home.objectID
            }
        }
        homeResolutionTask = task
        do {
            return try await task.value
        } catch {
            homeResolutionTask = nil
            throw error
        }
    }

    private func updatePlant(id: UUID, changes: @escaping @Sendable (CDPlant) -> Void) async throws {
        let context = backgroundContext()
        try await context.perform {
            let plant = try Self.fetchPlant(id: id, in: context)
            changes(plant)
            try context.save()
        }
        postChange()
    }

    private func backgroundContext() -> NSManagedObjectContext {
        let context = persistence.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private func postChange(eventID: UUID? = nil) {
        NotificationCenter.default.post(name: .plantStoreDidChange, object: eventID)
    }

    private static func resolveHome(
        in context: NSManagedObjectContext,
        persistence: PersistenceController,
        createIfMissing: Bool
    ) throws -> CDHome {
        if let sharedStore = persistence.sharedStore,
           let shared = try fetchHome(in: context, stores: [sharedStore]) {
            return shared
        }
        let privateStores = persistence.container.persistentStoreCoordinator.persistentStores
            .filter { $0 != persistence.sharedStore }
        if let privateHome = try fetchHome(in: context, stores: privateStores) {
            return privateHome
        }
        guard createIfMissing else { throw PlantRepositoryError.homeUnavailable }

        let home = CDHome(context: context)
        home.id = UUID()
        home.name = String(localized: "Our Home")
        home.createdAt = .now
        if let privateStore = privateStores.first {
            context.assign(home, to: privateStore)
        }
        try context.save()
        return home
    }

    private static func fetchHome(
        in context: NSManagedObjectContext,
        stores: [NSPersistentStore]
    ) throws -> CDHome? {
        guard !stores.isEmpty else { return nil }
        let request = CDHome.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.affectedStores = stores
        return try context.fetch(request).first
    }

    private static func fetchPlant(id: UUID, in context: NSManagedObjectContext) throws -> CDPlant {
        let request = CDPlant.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let plant = try context.fetch(request).first else {
            throw PlantRepositoryError.plantNotFound
        }
        return plant
    }

    private static func assign(
        _ object: NSManagedObject,
        with home: CDHome,
        in context: NSManagedObjectContext
    ) {
        if let store = home.objectID.persistentStore {
            context.assign(object, to: store)
        }
    }

    private static func validated(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PlantRepositoryError.invalidName }
        return trimmed
    }
}
