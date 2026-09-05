import CoreData

@objc(CDHome)
nonisolated final class CDHome: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var plants: Set<CDPlant>?

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDHome> {
        NSFetchRequest<CDHome>(entityName: "CDHome")
    }
}
