import SwiftUI

struct BotanicalBackground: View {
    var body: some View {
        ZStack {
            Palette.cream
            RadialGradient(
                colors: [Palette.sage.opacity(0.9), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 340
            )
            RadialGradient(
                colors: [Color(hex: 0xF3F0DE).opacity(0.8), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 280
            )
        }
        .ignoresSafeArea()
    }
}
