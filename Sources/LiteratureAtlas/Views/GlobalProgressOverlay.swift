import SwiftUI

@available(macOS 26, iOS 26, *)
struct GlobalProgressOverlay: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            Spacer()
            if model.isIngesting || model.isClustering {
                GlassCard(tint: model.isIngesting ? GalaxyTheme.cometMint : GalaxyTheme.nebulaViolet, prominence: .hero) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill((model.isIngesting ? GalaxyTheme.cometMint : GalaxyTheme.nebulaViolet).opacity(0.18))
                            Image(systemName: model.isIngesting ? "tray.and.arrow.down.fill" : "circle.hexagongrid.fill")
                                .foregroundStyle(model.isIngesting ? GalaxyTheme.cometMint : GalaxyTheme.nebulaViolet)
                                .font(.title3.bold())
                        }
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(statusText)
                                .font(.headline)
                            Text(subtitleText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            ProgressView(value: progressValue)
                                .tint(model.isIngesting ? GalaxyTheme.cometMint : GalaxyTheme.nebulaViolet)
                                .frame(width: 240)
                        }
                        Spacer(minLength: 10)
                        Button {
                            if model.isIngesting { model.cancelIngestion() }
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(!model.isIngesting)
                    }
                }
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9), value: model.isIngesting || model.isClustering)
            }
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(model.isIngesting)
    }

    private var progressValue: Double {
        if model.isIngesting { return model.ingestionProgress }
        if model.isClustering { return model.clusteringProgress }
        return 0
    }

    private var statusText: String {
        if model.isIngesting { return "Ingesting PDFs" }
        if model.isClustering { return "Clustering" }
        return "Idle"
    }

    private var subtitleText: String {
        if model.isIngesting {
            let current = model.ingestionCurrentFile.isEmpty ? "" : " · " + model.ingestionCurrentFile
            return "\(model.ingestionCompletedCount)/\(max(model.ingestionTotalCount, 1)) files\(current)"
        }
        if model.isClustering {
            return String(format: "%.0f%%", model.clusteringProgress * 100)
        }
        return ""
    }
}
