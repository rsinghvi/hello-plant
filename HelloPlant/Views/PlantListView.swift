import SwiftUI
import UIKit

struct PlantListView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: PlantListViewModel
    @State private var sharingController: UICloudSharingController?
    @State private var shareError: String?
    @State private var participantNames: [String] = []
    @State private var sharingAccess: SharingAccess = .unshared
    @State private var path: [PlantStatus] = []

    private let repository: any PlantRepository

    init(
        repository: any PlantRepository,
        profile: LocalProfile,
        syncObserver: SyncStatusObserver
    ) {
        self.repository = repository
        _viewModel = State(
            initialValue: PlantListViewModel(
                repository: repository,
                profile: profile,
                syncObserver: syncObserver
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                BotanicalBackground()
                VStack(spacing: 0) {
                    HomeHeaderView(
                        displayName: viewModel.profile.displayName,
                        statuses: viewModel.statuses,
                        participantNames: participantNames
                    )
                    syncStatus
                    if viewModel.statuses.isEmpty {
                        emptyState
                    } else {
                        plantList
                    }
                }

                if let plantID = viewModel.recentlyWateredPlantID,
                   let plant = viewModel.statuses.first(where: { $0.id == plantID }) {
                    UndoBanner(
                        plantName: plant.plant.name,
                        displayName: viewModel.profile.displayName
                    ) {
                        Task { await viewModel.undoLastWatering() }
                    }
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: viewModel.recentlyWateredPlantID)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.isShowingArchived = true
                        } label: {
                            Label("Archived plants", systemImage: "archivebox")
                        }
                        Button {
                            prepareShare()
                        } label: {
                            Label(shareActionTitle, systemImage: "person.crop.circle.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Home options")

                    Button {
                        viewModel.isAddingPlant = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Palette.leaf)
                            .clipShape(Circle())
                            .shadow(color: Palette.leaf.opacity(0.35), radius: 6, y: 3)
                    }
                    .accessibilityLabel("Add a plant")
                }
            }
            .sheet(isPresented: $viewModel.isAddingPlant) {
                AddPlantView { name, iconName in
                    await viewModel.addPlant(name: name, iconName: iconName)
                }
            }
            .sheet(isPresented: $viewModel.isShowingArchived) {
                ArchivedPlantsView(statuses: viewModel.archivedStatuses) {
                    await viewModel.restore($0)
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { sharingController != nil },
                    set: { if !$0 { sharingController = nil } }
                )
            ) {
                if let sharingController {
                    CloudSharingView(controller: sharingController)
                }
            }
            .navigationDestination(for: PlantStatus.self) { status in
                PlantDetailView(
                    status: status,
                    repository: repository,
                    profile: viewModel.profile
                )
            }
            .task {
                await viewModel.load()
                await loadParticipants()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil || shareError != nil },
                    set: {
                        if !$0 {
                            viewModel.clearError()
                            shareError = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? shareError ?? "")
            }
        }
        .tint(Palette.leafDark)
    }

    private var plantList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.statuses) { status in
                    PlantCardView(
                        status: status,
                        currentDisplayName: viewModel.profile.displayName,
                        isRecentlyWatered: viewModel.recentlyWateredPlantID == status.id,
                        detailAction: {
                            path.append(status)
                        },
                        waterAction: {
                            Task { await viewModel.water(status) }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, viewModel.lastLocalEventID == nil ? 24 : 110)
        }
        .refreshable { await viewModel.load() }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Let’s add your first plant", systemImage: "leaf.fill")
                .foregroundStyle(Palette.leafDeep)
        } description: {
            Text("Add the plants in your home so everyone can see when they were last watered.")
        } actions: {
            Button {
                viewModel.isAddingPlant = true
            } label: {
                Label("Add a plant", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 48)
                    .foregroundStyle(.white)
                    .background(Palette.actionGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var syncStatus: some View {
        switch viewModel.syncObserver.status {
        case .idle:
            Label("Up to date", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(Palette.inkTertiary)
                .symbolRenderingMode(.monochrome)
        case .syncing:
            Label("Syncing…", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(Palette.inkTertiary)
        case .error:
            Label("Offline — your changes will sync later", systemImage: "airplane")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: 0x8A6218))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: 0xFDF3DF))
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
    }

    private func prepareShare() {
        Task {
            do {
                sharingController = try await environment.sharingController()
                await loadParticipants()
            } catch {
                shareError = error.localizedDescription
            }
        }
    }

    private func loadParticipants() async {
        do {
            async let names = environment.participantNames()
            async let access = environment.sharingAccess()
            participantNames = try await names
            sharingAccess = try await access
        } catch {
            participantNames = []
            sharingAccess = .unshared
            shareError = error.localizedDescription
        }
    }

    private var shareActionTitle: String {
        switch sharingAccess {
        case .unshared: String(localized: "Share home")
        case .owner: String(localized: "Manage sharing")
        case .participant: String(localized: "Stop using shared plants")
        }
    }
}
