import CoreData

@objc(CDWateringEvent)
nonisolated final class CDWateringEvent: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var wateredAt: Date?
    @NSManaged var wateredBy: String?
    @NSManaged var createdAt: Date?
    @NSManaged var plant: CDPlant?

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDWateringEvent> {
        NSFetchRequest<CDWateringEvent>(entityName: "CDWateringEvent")
    }
}
