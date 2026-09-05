import Testing
@testable import HelloPlant

@MainActor
struct PlantAccentTests {
    @Test func everyPresetIsDeterministic() {
        for icon in PlantIcon.presets {
            #expect(
                PlantAccent.color(for: icon.name) == PlantAccent.color(for: icon.name)
            )
        }
    }

    @Test func nilAndUnknownIconsUseLeafAccent() {
        #expect(PlantAccent.color(for: nil) == Palette.leaf)
        #expect(PlantAccent.color(for: "unknown") == Palette.leaf)
    }
}
