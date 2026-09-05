import Foundation

struct Home: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var createdAt: Date
}
