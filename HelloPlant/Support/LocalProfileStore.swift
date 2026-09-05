import Foundation

@MainActor
final class LocalProfileStore {
    private enum Key {
        static let displayName = "profile.displayName"
        static let installationIdentifier = "profile.installationIdentifier"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var profile: LocalProfile? {
        guard let displayName = defaults.string(forKey: Key.displayName),
              !displayName.isEmpty else {
            return nil
        }
        return LocalProfile(displayName: displayName, installationIdentifier: installationIdentifier)
    }

    func save(displayName: String) -> LocalProfile {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed, forKey: Key.displayName)
        return LocalProfile(displayName: trimmed, installationIdentifier: installationIdentifier)
    }

    private var installationIdentifier: UUID {
        if let value = defaults.string(forKey: Key.installationIdentifier),
           let identifier = UUID(uuidString: value) {
            return identifier
        }
        let identifier = UUID()
        defaults.set(identifier.uuidString, forKey: Key.installationIdentifier)
        return identifier
    }
}
