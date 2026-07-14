import SwiftUI

/// Palette et styles inspirés du design system Apple (océan, verre dépoli).
enum Theme {
    static let deepBlue = Color(red: 0.04, green: 0.20, blue: 0.36)
    static let ocean = Color(red: 0.02, green: 0.45, blue: 0.72)
    static let surf = Color(red: 0.36, green: 0.78, blue: 0.92)
    static let sand = Color(red: 0.96, green: 0.90, blue: 0.78)

    /// Dégradé de fond principal, adapté au mode sombre/clair.
    static func background(_ scheme: ColorScheme) -> LinearGradient {
        let colors: [Color] = scheme == .dark
            ? [Color(red: 0.03, green: 0.09, blue: 0.18), Color(red: 0.02, green: 0.16, blue: 0.30)]
            : [surf.opacity(0.35), ocean.opacity(0.55)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    static let tideGradient = LinearGradient(
        colors: [surf, ocean],
        startPoint: .top, endPoint: .bottom
    )
}

/// Carte translucide arrondie, style widget Apple.
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 18, y: 10)
    }
}
