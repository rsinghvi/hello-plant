import Foundation

struct PlantIcon: Identifiable, Hashable, Sendable {
    let name: String
    let label: String

    var id: String { name }

    static let presets = [
        PlantIcon(name: "leaf.fill", label: "Leaf"),
        PlantIcon(name: "camera.macro", label: "Flower"),
        PlantIcon(name: "tree.fill", label: "Tree"),
        PlantIcon(name: "microbe.fill", label: "Succulent"),
        PlantIcon(name: "fan.fill", label: "Palm"),
        PlantIcon(name: "laurel.leading", label: "Vine")
    ]

    static let defaultName = presets[0].name
}
