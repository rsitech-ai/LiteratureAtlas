import SwiftUI

@available(macOS 26, iOS 26, *)
struct ChartZoomControls: View {
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onZoomOut) {
                Image(systemName: "minus.magnifyingglass")
            }
            .accessibilityLabel("Zoom out")
            .help("Zoom out")
            Button(action: onZoomIn) {
                Image(systemName: "plus.magnifyingglass")
            }
            .accessibilityLabel("Zoom in")
            .help("Zoom in")
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
            }
            .accessibilityLabel("Reset chart view")
            .help("Reset chart view")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
