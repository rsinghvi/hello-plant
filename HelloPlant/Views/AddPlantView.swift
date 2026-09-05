import SwiftUI

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = PlantIcon.defaultName
    @State private var isSaving = false
    let save: (String, String) async -> Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BotanicalBackground()
                Form {
                    Section("NAME") {
                        TextField("Peace Lily", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    Section("PICK AN ICON") {
                        PlantIconPicker(selection: $iconName)
                    }
                    Section {
                        Text("Everyone in your home will see this plant.")
                            .font(.footnote)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        isSaving = true
                        Task {
                            if await save(name, iconName) { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .tint(Palette.leafDark)
    }
}
