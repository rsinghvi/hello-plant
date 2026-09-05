import Foundation

struct LocalProfile: Hashable, Sendable {
    var displayName: String
    let installationIdentifier: UUID
}
