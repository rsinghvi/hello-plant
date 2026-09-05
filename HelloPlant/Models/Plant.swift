import Foundation

struct Plant: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var createdAt: Date
    var archivedAt: Date?
    var iconName: String?
}
