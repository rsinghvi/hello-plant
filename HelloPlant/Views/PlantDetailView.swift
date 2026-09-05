import SwiftUI

struct PlantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlantDetailViewModel

    init(status: PlantStatus, repository: any PlantRepository, profile: LocalProfile) {
        _viewModel = State(
            initialValue: PlantDetailViewModel(
                status: status,
                repository: repository,
                profile: profile
            )
        )
    }

    var body: some View {
        ZStack {
            BotanicalBackground()
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    history
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(viewModel.status.plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { viewModel.isEditing = true }
            }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            EditPlantView(
                plant: viewModel.status.plant,
                save: { name, icon in await viewModel.save(name: name, iconName: icon) },
                archive: {
                    let archived = await viewModel.archive()
                    if archived { dismiss() }
                    return archived
                }
            )
        }
        .task { await viewModel.load() }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .tint(Palette.leafDark)
    }

    private var hero: some View {
        let status = viewModel.status
        let accent = PlantAccent.accent(for: status.plant.iconName)
        return VStack(spacing: 8) {
            Image(systemName: status.plant.iconName ?? PlantIcon.defaultName)
                .font(.system(size: 36))
                .foregroundStyle(accent.color)
                .frame(width: 76, height: 76)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: Palette.leafDeep.opacity(0.13), radius: 8, y: 4)
            Text(heroTitle)
                .font(.title3.bold())
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            if let event = status.lastEvent {
                Text("by \(event.wateredBy) · \(event.wateredAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
            }
            Button {
                Task { await viewModel.water() }
            } label: {
                Label("Watered Now", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(.white)
                    .background(Palette.actionGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Palette.leafDark.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.top, 8)
            .accessibilityHint("Records a watering by you")
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [accent.tint, .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var heroTitle: String {
        guard viewModel.status.lastEvent != nil else {
            return String(localized: "Never watered")
        }
        return String(
            localized: "Watered \(RelativeDateText.display(for: viewModel.status.lastEvent?.wateredAt).lowercased())"
        )
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HISTORY")
                .font(.caption.bold())
                .tracking(1.1)
                .foregroundStyle(Palette.inkTertiary)
                .padding(.top, 20)
                .padding(.horizontal, 8)
            if viewModel.history.isEmpty {
                Text("Watering events will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                ForEach(viewModel.history) { event in
                    HStack(spacing: 10) {
                        PersonChip(
                            name: event.wateredBy,
                            currentDisplayName: viewModel.profile.displayName
                        )
                        Spacer()
                        Text(event.wateredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Palette.inkTertiary)
                    }
                    .padding(12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Palette.leafDeep.opacity(0.06), radius: 4, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
