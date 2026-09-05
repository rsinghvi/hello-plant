import SwiftUI

struct PlantIconPicker: View {
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PlantIcon.presets) { icon in
                    let accent = PlantAccent.accent(for: icon.name)
                    Button {
                        selection = icon.name
                    } label: {
                        Image(systemName: icon.name)
                            .font(.title2)
                            .foregroundStyle(accent.color)
                            .frame(width: 52, height: 52)
                            .background(accent.tint.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        selection == icon.name ? Palette.leaf : .clear,
                                        lineWidth: 3
                                    )
                            }
                    }
                    .accessibilityLabel(icon.label)
                    .accessibilityValue(selection == icon.name ? "Selected" : "")
                }
            }
            .padding(.vertical, 4)
        }
    }
}
