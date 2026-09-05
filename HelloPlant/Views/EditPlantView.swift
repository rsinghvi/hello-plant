import SwiftUI

struct EditPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var iconName: String
    @State private var isArchiving = false

    let save: (String, String) async -> Bool
    let archive: () async -> Bool

    init(
        plant: Plant,
        save: @escaping (String, String) async -> Bool,
        archive: @escaping () async -> Bool
    ) {
        _name = State(initialValue: plant.name)
        _iconName = State(initialValue: plant.iconName ?? PlantIcon.defaultName)
        self.save = save
        self.archive = archive
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BotanicalBackground()
                Form {
                    Section("NAME") {
                        TextField("Plant name", text: $name)
                    }
                    Section("ICON") {
                        PlantIconPicker(selection: $iconName)
                    }
                    Section("ARCHIVE") {
                        Button(role: .destructive) {
                            isArchiving = true
                        } label: {
                            Label("Archive plant", systemImage: "archivebox")
                        }
                        Text("Archived plants are hidden for everyone in your home. Their watering history is kept and you can restore them later.")
                            .font(.footnote)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await save(name, iconName) { dismiss() }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .confirmationDialog(
                "Archive \(name)?",
                isPresented: $isArchiving,
                titleVisibility: .visible
            ) {
                Button("Archive plant", role: .destructive) {
                    Task {
                        if await archive() { dismiss() }
                    }
                }
            } message: {
                Text("Its watering history will be kept.")
            }
        }
        .tint(Palette.leafDark)
    }
}
