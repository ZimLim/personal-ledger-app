import SwiftUI

/// Minimal greyscale design language (RFC §6.1). No accent colors — the primary
/// button inverts foreground/background so it reads black-on-white (light) and
/// white-on-black (dark).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primary)
            .foregroundStyle(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
