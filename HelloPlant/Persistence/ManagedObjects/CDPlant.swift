import CoreData

@objc(CDPlant)
nonisolated final class CDPlant: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var archivedAt: Date?
    @NSManaged var iconName: String?
    @NSManaged var home: CDHome?
    @NSManaged var wateringEvents: Set<CDWateringEvent>?

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDPlant> {
        NSFetchRequest<CDPlant>(entityName: "CDPlant")
    }
}
