import SwiftUI

@available(macOS 26, iOS 26, *)
struct GlassCard<Content: View>: View {
    enum Prominence {
        case normal
        case hero
        case compact
    }

    var tint: Color = GalaxyTheme.nebulaBlue
    var prominence: Prominence = .normal
    var content: () -> Content

    init(
        tint: Color = GalaxyTheme.nebulaBlue,
        prominence: Prominence = .normal,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tint = tint
        self.prominence = prominence
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(backgroundOpacity))
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(GalaxyTheme.cardGradient)
                        .blendMode(.overlay)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [tint.opacity(tintOpacity), .clear],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: prominence == .hero ? 420 : 260
                            )
                        )
                        .blendMode(.screen)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: prominence == .hero ? 1.4 : 1)
            )
            .shadow(color: tint.opacity(prominence == .hero ? 0.18 : 0.10), radius: prominence == .hero ? 26 : 14, x: 0, y: 0)
            .shadow(color: .black.opacity(0.30), radius: prominence == .compact ? 8 : 16, x: 0, y: 10)
    }

    private var padding: CGFloat {
        switch prominence {
        case .normal: return 16
        case .hero: return 22
        case .compact: return 12
        }
    }

    private var backgroundOpacity: Double {
        switch prominence {
        case .normal: return 0.34
        case .hero: return 0.42
        case .compact: return 0.26
        }
    }

    private var tintOpacity: Double {
        switch prominence {
        case .normal: return 0.10
        case .hero: return 0.20
        case .compact: return 0.07
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(prominence == .hero ? 0.30 : 0.18),
                tint.opacity(prominence == .hero ? 0.34 : 0.22),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
