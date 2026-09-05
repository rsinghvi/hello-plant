import SwiftUI

struct PlantAccent: Equatable {
    let color: Color
    let tint: Color

    static func accent(for iconName: String?) -> PlantAccent {
        switch iconName {
        case "camera.macro":
            PlantAccent(color: Palette.terracotta, tint: Color(hex: 0xFBEDE6))
        case "tree.fill":
            PlantAccent(color: Palette.sun, tint: Color(hex: 0xFDF3DF))
        case "microbe.fill":
            PlantAccent(color: Palette.sky, tint: Color(hex: 0xE7F2FA))
        case "fan.fill":
            PlantAccent(color: Palette.lilac, tint: Color(hex: 0xF1ECFA))
        case "laurel.leading":
            PlantAccent(color: Palette.rose, tint: Color(hex: 0xFBEAF0))
        default:
            PlantAccent(color: Palette.leaf, tint: Palette.sageLight)
        }
    }

    static func color(for iconName: String?) -> Color {
        accent(for: iconName).color
    }
}
