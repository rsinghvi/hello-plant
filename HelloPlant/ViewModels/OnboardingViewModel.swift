import Foundation
import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    var displayName = ""
    private(set) var validationMessage: String?
    private let profileStore: LocalProfileStore

    init(profileStore: LocalProfileStore) {
        self.profileStore = profileStore
    }

    @discardableResult
    func continueTapped() -> LocalProfile? {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            validationMessage = String(localized: "Enter your name to continue.")
            return nil
        }
        validationMessage = nil
        return profileStore.save(displayName: name)
    }
}
