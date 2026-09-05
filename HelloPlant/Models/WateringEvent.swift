import Foundation

struct WateringEvent: Identifiable, Hashable, Sendable {
    let id: UUID
    var wateredAt: Date
    var wateredBy: String
    var createdAt: Date
    var plantID: UUID
}
