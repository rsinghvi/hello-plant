import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    let completed: (LocalProfile) -> Void

    init(profileStore: LocalProfileStore, completed: @escaping (LocalProfile) -> Void) {
        _viewModel = State(initialValue: OnboardingViewModel(profileStore: profileStore))
        self.completed = completed
    }

    var body: some View {
        ZStack {
            BotanicalBackground()
            Image(systemName: "leaf.fill")
                .font(.system(size: 180))
                .foregroundStyle(Palette.leaf.opacity(0.06))
                .rotationEffect(.degrees(-20))
                .offset(x: -130, y: -270)

            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "camera.macro")
                        .font(.system(size: 58))
                        .foregroundStyle(Palette.leaf)
                        .padding(.top, 70)
                    Text("HelloPlant")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Palette.leafDeep)
                        .padding(.top, 12)
                    Text("Know who watered the plants,\nand when.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.inkSecondary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHAT SHOULD WE CALL YOU?")
                            .font(.caption.bold())
                            .tracking(1.1)
                            .foregroundStyle(Palette.inkTertiary)
                        TextField("Your name", text: $viewModel.displayName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .font(.title3)
                            .padding(15)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Palette.leafDeep.opacity(0.08), radius: 6, y: 3)
                        Text("Housemates see this name next to the plants you water.")
                            .font(.footnote)
                            .foregroundStyle(Palette.inkSecondary)
                        if let validationMessage = viewModel.validationMessage {
                            Text(validationMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.top, 42)

                    Button {
                        if let profile = viewModel.continueTapped() {
                            completed(profile)
                        }
                    } label: {
                        Text("Let’s grow")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(.white)
                            .background(Palette.actionGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 17))
                            .shadow(color: Palette.leafDark.opacity(0.3), radius: 9, y: 5)
                    }
                    .padding(.top, 22)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
