import SwiftUI
import UniformTypeIdentifiers
import FoundationModels

@available(macOS 26, iOS 26, *)
struct IngestView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showFolderPicker = false
    @State private var assumptionQuery: String = ""
    @State private var assumptionNarrative: String = ""
    @State private var topEdges: [ClaimEdge] = []
    @State private var hasLoadedClaimPreview = false
    @State private var isLoadingClaimPreview = false
    @State private var showStyleTips = false
    @State private var selectedPaper: Paper?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    overviewMetrics
                    commandCenterCard
                    activityCard
                    logCard

                    if !model.papers.isEmpty {
                        ReadingPlannerCard(selectedPaper: $selectedPaper)
                        claimGraphCard
                        assumptionStressCard
                    }

                    Spacer(minLength: 24)
                }
                .padding()
            }
            .navigationTitle("Literature Atlas")
        }
        .sheet(item: $selectedPaper) { paper in
            PaperDetailView(paper: paper)
                .environmentObject(model)
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let folder = urls.first {
                    model.ingestFolder(url: folder)
                    showStyleTips = true
                }
            case .failure(let error):
                model.ingestionLog += "\nFolder picker error: \(error.localizedDescription)"
            }
        }
    }

    private var headerCard: some View {
        GalaxyHeroCard(
            eyebrow: "Step 1",
            title: "Ingest Documents",
            subtitle: "Pull PDFs and Markdown into the atlas, build cited summaries, and compile durable knowledge artifacts into the repo Output folder.",
            systemImage: "sparkles.rectangle.stack",
            tint: GalaxyTheme.cometMint
        ) {
            availabilityBadge
        }
    }

    private var overviewMetrics: some View {
        HStack(spacing: 12) {
            GalaxyMetricTile(
                title: "Documents",
                value: "\(model.papers.count)",
                systemImage: "doc.text.fill",
                tint: GalaxyTheme.nebulaBlue
            )
            GalaxyMetricTile(
                title: "Succeeded",
                value: "\(model.ingestionCompletedCount)",
                systemImage: "checkmark.seal.fill",
                tint: GalaxyTheme.cometMint
            )
            GalaxyMetricTile(
                title: "Progress",
                value: String(format: "%.0f%%", model.ingestionProgress * 100),
                systemImage: "waveform.path.ecg",
                tint: model.isIngesting ? GalaxyTheme.solarGold : GalaxyTheme.nebulaViolet
            )
        }
    }

    private var commandCenterCard: some View {
        GlassCard(tint: GalaxyTheme.cometMint, prominence: .hero) {
            VStack(alignment: .leading, spacing: 14) {
                GalaxySectionHeader(
                    "Corpus intake",
                    subtitle: "Select a source folder and keep this window open while the atlas processes files.",
                    systemImage: "tray.and.arrow.down.fill",
                    tint: GalaxyTheme.cometMint
                )

                HStack(spacing: 12) {
                    GalaxyPrimaryActionButton(
                        title: "Select Folder of Documents",
                        systemImage: "folder.fill",
                        tint: GalaxyTheme.cometMint
                    ) {
                        showFolderPicker = true
                    }
                    .disabled(model.isIngesting)

                    Button {
                        model.cancelIngestion()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(minWidth: 92)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(!model.isIngesting)
                }

                if let folder = model.selectedFolder {
                    GalaxyStatusPill(
                        "Selected: \(folder.lastPathComponent)",
                        systemImage: "checkmark.folder.fill",
                        tint: GalaxyTheme.cometMint
                    )
                }

                ProgressView(value: model.ingestionProgress)
                    .tint(GalaxyTheme.cometMint)
                    .animation(.easeInOut, value: model.ingestionProgress)

                HStack(spacing: 10) {
                    GalaxyStatusPill(
                        "\(model.ingestionCompletedCount) succeeded · \(model.ingestionSkippedCount) skipped · \(model.ingestionFailedCount) failed",
                        systemImage: "number",
                        tint: GalaxyTheme.nebulaBlue,
                        isPulsing: model.isIngesting
                    )

                    if !model.sourceKindCounts.isEmpty {
                        GalaxyStatusPill(
                            model.sourceKindCounts.map { "\($0.key.label): \($0.value)" }.sorted().joined(separator: "  "),
                            systemImage: "doc.on.doc",
                            tint: GalaxyTheme.nebulaViolet
                        )
                    }

                    if !model.ingestionCurrentFile.isEmpty {
                        Text("Now: \(model.ingestionCurrentFile)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
    }

    private var activityCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaViolet) {
            VStack(alignment: .leading, spacing: 12) {
                GalaxySectionHeader("Activity", subtitle: "Live pipeline state", systemImage: "dot.radiowaves.left.and.right", tint: GalaxyTheme.nebulaViolet)
                ingestStatusRow

                if let latest = latestIngestedPaper {
                    Divider().opacity(0.45).padding(.vertical, 2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last processed")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(latest.title)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                        HStack(spacing: 10) {
                            if let year = latest.year {
                                GalaxyStatusPill("Year \(year)", systemImage: "calendar", tint: GalaxyTheme.solarGold)
                            }
                            if let pages = latest.pageCount {
                                GalaxyStatusPill("\(pages) pages", systemImage: "doc.on.doc", tint: GalaxyTheme.nebulaBlue)
                            }
                        }
                    }
                }
            }
        }
    }

    private var logCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaBlue) {
            VStack(alignment: .leading, spacing: 10) {
                GalaxySectionHeader("Operations log", subtitle: "Searchable ingestion and analytics trace", systemImage: "terminal.fill", tint: GalaxyTheme.nebulaBlue)
                if showStyleTips {
                    Text("Keep this view open while processing; clustering and analytics can continue after ingest.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                InteractiveLogPanel(title: "Log", text: $model.ingestionLog, minHeight: 240)
            }
        }
    }

    private var availabilityBadge: some View {
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            return AnyView(
                GalaxyStatusPill("On-device model ready", systemImage: "checkmark.circle.fill", tint: GalaxyTheme.cometMint)
            )
        case .unavailable(let reason):
            return AnyView(
                GalaxyStatusPill("Model unavailable", systemImage: "exclamationmark.triangle", tint: GalaxyTheme.solarGold)
                    .overlay(
                        Text(String(describing: reason))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 30), alignment: .topLeading
                    )
            )
        }
    }

    private var ingestStatusRow: some View {
        HStack(spacing: 12) {
            GalaxyStatusPill(
                model.isIngesting ? "Ingesting" : "Idle",
                systemImage: model.isIngesting ? "bolt.horizontal.fill" : "moon.stars.fill",
                tint: model.isIngesting ? GalaxyTheme.cometMint : .secondary,
                isPulsing: model.isIngesting
            )
            GalaxyStatusPill(
                model.isClustering ? "Clustering" : "Not clustering",
                systemImage: "circle.hexagongrid.fill",
                tint: model.isClustering ? GalaxyTheme.nebulaBlue : .secondary,
                isPulsing: model.isClustering
            )
            GalaxyStatusPill("Documents: \(model.papers.count)", systemImage: "doc.text.fill", tint: GalaxyTheme.nebulaViolet)
        }
    }

    private var claimGraphCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaPink) {
            VStack(alignment: .leading, spacing: 10) {
                GalaxySectionHeader(
                    "Claim graph",
                    subtitle: "Shows how claims support, extend, or contradict each other across papers.",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    tint: GalaxyTheme.nebulaPink
                )
                if !hasLoadedClaimPreview {
                    Text("Generate a preview when you want to inspect how claims support, extend, or contradict each other.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if topEdges.isEmpty {
                    Text("No claim relations found in the current corpus preview.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    GalaxyStatusPill("Top relations", systemImage: "link", tint: GalaxyTheme.nebulaPink)
                    ForEach(topEdges.prefix(5), id: \.id) { edge in
                        if let source = model.papers.first(where: { $0.claims?.contains(where: { $0.id == edge.sourceClaimID }) == true })?.title,
                           let target = model.papers.first(where: { $0.claims?.contains(where: { $0.id == edge.targetClaimID }) == true })?.title {
                            HStack(alignment: .top, spacing: 6) {
                                Text(edge.kind.rawValue.capitalized)
                                    .font(.caption2.bold())
                                    .padding(6)
                                    .background(GalaxyTheme.nebulaBlue.opacity(0.14), in: Capsule())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("From \(source) → \(target)")
                                        .font(.subheadline)
                                    if let rationale = edge.rationale {
                                        Text(rationale)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                Button {
                    refreshClaimPreview()
                } label: {
                    Label(
                        isLoadingClaimPreview ? "Generating preview" : "Refresh relations",
                        systemImage: isLoadingClaimPreview ? "hourglass" : "arrow.clockwise"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingClaimPreview)
            }
        }
    }

    private func refreshClaimPreview() {
        guard !isLoadingClaimPreview else { return }
        isLoadingClaimPreview = true
        let claims = model.papers.flatMap { $0.claims ?? [] }

        Task.detached(priority: .userInitiated) {
            let edges = ClaimRelationInferencer.inferEdges(for: claims, limit: 25)
            await MainActor.run {
                topEdges = edges
                hasLoadedClaimPreview = true
                isLoadingClaimPreview = false
            }
        }
    }

    private var assumptionStressCard: some View {
        GlassCard(tint: GalaxyTheme.solarGold) {
            VStack(alignment: .leading, spacing: 10) {
                GalaxySectionHeader(
                    "Assumption stress test",
                    subtitle: "Pick an assumption and see which claims rely on it.",
                    systemImage: "exclamationmark.shield.fill",
                    tint: GalaxyTheme.solarGold
                )
                HStack(alignment: .top) {
                    TextField("e.g., infinite liquidity", text: $assumptionQuery, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        let trimmed = assumptionQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let report = model.assumptionStressReport(for: trimmed)
                        assumptionNarrative = report.narrative
                    } label: {
                        Label("Run", systemImage: "exclamationmark.shield")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.papers.isEmpty)
                }
                if !assumptionNarrative.isEmpty {
                    Text(assumptionNarrative)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var availabilityBanner: some View {
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            Text("On-device language model: available")
                .font(.caption)
                .foregroundStyle(.green)
        case .unavailable(let reason):
            Text("On-device language model unavailable: \(String(describing: reason))")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
    
    private var latestIngestedPaper: Paper? {
        let papers = model.papers
        return papers.max(by: { ($0.ingestedAt ?? Date.distantPast) < ($1.ingestedAt ?? Date.distantPast) })
    }
}
