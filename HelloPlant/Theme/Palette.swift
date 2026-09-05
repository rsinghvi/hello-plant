import SwiftUI

enum Palette {
    static let cream = Color(hex: 0xFDFAF3)
    static let paper = Color.white
    static let sageLight = Color(hex: 0xEDF5EA)
    static let sage = Color(hex: 0xDCEBD6)
    static let leaf = Color(hex: 0x3E9B54)
    static let leafDark = Color(hex: 0x2A7340)
    static let leafDeep = Color(hex: 0x1B4D2E)
    static let ink = Color(hex: 0x20301F)
    static let inkSecondary = Color(hex: 0x6B7A69)
    static let inkTertiary = Color(hex: 0x9AA898)
    static let terracotta = Color(hex: 0xD9825C)
    static let sun = Color(hex: 0xEFB43C)
    static let sky = Color(hex: 0x5FA8D3)
    static let lilac = Color(hex: 0x9B7EC8)
    static let rose = Color(hex: 0xD96A8B)

    static let actionGradient = LinearGradient(
        colors: [Color(hex: 0x4FB06A), leafDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
