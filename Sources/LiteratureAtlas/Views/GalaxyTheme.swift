import SwiftUI

@available(macOS 26, iOS 26, *)
enum GalaxyTheme {
    static let void = Color(red: 0.025, green: 0.030, blue: 0.060)
    static let deepSpace = Color(red: 0.055, green: 0.070, blue: 0.140)
    static let nebulaBlue = Color(red: 0.22, green: 0.72, blue: 1.00)
    static let nebulaViolet = Color(red: 0.55, green: 0.40, blue: 1.00)
    static let nebulaPink = Color(red: 1.00, green: 0.36, blue: 0.72)
    static let solarGold = Color(red: 1.00, green: 0.78, blue: 0.28)
    static let cometMint = Color(red: 0.35, green: 0.95, blue: 0.72)
    static let ember = Color(red: 1.00, green: 0.44, blue: 0.26)

    static let baseGradient = LinearGradient(
        colors: [
            Color(red: 0.020, green: 0.024, blue: 0.055),
            Color(red: 0.050, green: 0.052, blue: 0.140),
            Color(red: 0.030, green: 0.080, blue: 0.160)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [nebulaBlue, nebulaViolet, nebulaPink, solarGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.100),
            Color.white.opacity(0.040),
            nebulaBlue.opacity(0.040)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

@available(macOS 26, iOS 26, *)
struct GalaxyBackdrop: View {
    var intensity: Double = 1.0

    var body: some View {
        GalaxyTheme.baseGradient
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

@available(macOS 26, iOS 26, *)
struct GalaxyHeroCard<Trailing: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @ViewBuilder var trailing: () -> Trailing

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color = GalaxyTheme.nebulaBlue,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        GlassCard(tint: tint, prominence: .hero) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.22))
                    Circle()
                        .stroke(tint.opacity(0.52), lineWidth: 1)
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 64, height: 64)
                .shadow(color: tint.opacity(0.45), radius: 22, x: 0, y: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                trailing()
            }
        }
    }
}

@available(macOS 26, iOS 26, *)
struct GalaxyMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
    }
}

@available(macOS 26, iOS 26, *)
struct GalaxyStatusPill: View {
    let title: String
    let systemImage: String?
    let tint: Color
    var isPulsing: Bool = false

    init(_ title: String, systemImage: String? = nil, tint: Color, isPulsing: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.isPulsing = isPulsing
    }

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.caption.bold())
        .padding(.vertical, 7)
        .padding(.horizontal, 11)
        .foregroundStyle(tint)
        .background(tint.opacity(isPulsing ? 0.20 : 0.13), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(isPulsing ? 0.44 : 0.28), lineWidth: 1))
        .shadow(color: tint.opacity(isPulsing ? 0.28 : 0.12), radius: isPulsing ? 14 : 8, x: 0, y: 0)
    }
}

@available(macOS 26, iOS 26, *)
struct GalaxyPrimaryActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }
}

@available(macOS 26, iOS 26, *)
struct GalaxySectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color

    init(_ title: String, subtitle: String? = nil, systemImage: String, tint: Color = GalaxyTheme.nebulaBlue) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}
