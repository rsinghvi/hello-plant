import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var profile: LocalProfile?

    var body: some View {
        Group {
            if let profile {
                PlantListView(
                    repository: environment.repository,
                    profile: profile,
                    syncObserver: environment.syncObserver
                )
            } else {
                OnboardingView(profileStore: environment.profileStore) {
                    profile = $0
                }
            }
        }
        .onAppear {
            if profile == nil {
                profile = environment.profileStore.profile
            }
        }
    }
}
