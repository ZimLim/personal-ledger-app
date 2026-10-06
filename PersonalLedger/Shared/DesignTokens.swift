import SwiftUI
import UIKit

/// Minimal greyscale design language (RFC §6.1). Explicit near-black / near-white
/// tokens (not the semantic `.primary`, which rendered washed-out grey on device
/// — improvement #2) so the primary button reads as a solid, clearly-tappable fill.
extension Color {
    /// Primary button fill: near-black (light) / near-white (dark).
    static let primaryFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.96, alpha: 1.0)
            : UIColor(white: 0.07, alpha: 1.0)
    })

    /// Label on the primary fill: inverse of `primaryFill`.
    static let onPrimaryFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.07, alpha: 1.0)
            : UIColor.white
    })

    /// Fill for the destructive swipe (Delete) button. A visible greyscale grey
    /// (not the inherited `.primary` tint, which turned the button white in dark
    /// mode and hid its icon) with white icon/label on top, legible in both modes.
    static let destructiveSwipe = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 0.34, alpha: 1.0)
            : UIColor(white: 0.20, alpha: 1.0)
    })
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primaryFill)
            .foregroundStyle(Color.onPrimaryFill)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
    }
}
