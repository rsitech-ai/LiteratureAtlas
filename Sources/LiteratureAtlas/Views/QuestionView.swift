import SwiftUI

@available(macOS 26, iOS 26, *)
struct QuestionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var localQuestion: String = ""

    private var trimmedQuestion: String {
        localQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero

                    if model.papers.isEmpty {
                        emptyState
                    } else {
                        yearFilterStrip
                        composerCard

                        if model.isAnswering {
                            thinkingCard
                        }

                        if !model.questionAnswer.isEmpty {
                            answerCard
                        }

                        if !model.questionTopPapers.isEmpty {
                            relevantDocumentsCard
                        }

                        if !model.questionEvidence.isEmpty {
                            evidenceCard
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Q&A")
        }
    }

    private var hero: some View {
        GalaxyHeroCard(
            eyebrow: "Step 3",
            title: "Question-driven map",
            subtitle: "Ask the atlas to retrieve compiled notes first, then source chunks, and synthesize a cited answer from your corpus.",
            systemImage: "questionmark.bubble.fill",
            tint: GalaxyTheme.nebulaPink
        ) {
            GalaxyStatusPill(
                "\(model.explorationPapers.count)/\(model.papers.count) docs",
                systemImage: "doc.text.magnifyingglass",
                tint: GalaxyTheme.nebulaPink,
                isPulsing: model.isAnswering
            )
        }
    }

    private var emptyState: some View {
        GlassCard(tint: GalaxyTheme.solarGold, prominence: .hero) {
            VStack(alignment: .leading, spacing: 12) {
                GalaxySectionHeader(
                    "No documents yet",
                    subtitle: "Ingest a source folder before asking corpus-level questions.",
                    systemImage: "tray.and.arrow.down.fill",
                    tint: GalaxyTheme.solarGold
                )
                Text("Once documents are indexed, this screen can search compiled notes, rank evidence, and produce cited synthesis.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var yearFilterStrip: some View {
        if model.yearFilterEnabled, let range = model.effectiveYearRange {
            GlassCard(tint: GalaxyTheme.solarGold, prominence: .compact) {
                HStack(spacing: 10) {
                    GalaxyStatusPill(
                        "Years \(range.lowerBound)-\(range.upperBound)",
                        systemImage: "calendar",
                        tint: GalaxyTheme.solarGold
                    )
                    if model.explorationPapers.isEmpty {
                        Text("No papers in this range. Clear the filter to search the full corpus.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Clear") { model.resetYearFilter() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
    }

    private var composerCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaPink, prominence: .hero) {
            VStack(alignment: .leading, spacing: 12) {
                GalaxySectionHeader(
                    "Ask the corpus",
                    subtitle: "Use broad research questions; the answer will include ranked sources and evidence chunks.",
                    systemImage: "sparkle.magnifyingglass",
                    tint: GalaxyTheme.nebulaPink
                )

                HStack(alignment: .top, spacing: 12) {
                    TextField("What are the main approaches to market microstructure modeling?", text: $localQuestion, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...5)

                    Button {
                        askCurrentQuestion()
                    } label: {
                        Label("Ask", systemImage: "paperplane.fill")
                            .frame(minWidth: 76)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GalaxyTheme.nebulaPink)
                    .disabled(model.isAnswering || trimmedQuestion.isEmpty)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
            }
        }
    }

    private var thinkingCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaBlue) {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(GalaxyTheme.nebulaBlue)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Thinking across the atlas")
                        .font(.headline)
                    Text("Retrieving compiled notes, source chunks, and similarity-ranked documents.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var answerCard: some View {
        GlassCard(tint: GalaxyTheme.cometMint, prominence: .hero) {
            VStack(alignment: .leading, spacing: 12) {
                GalaxySectionHeader(
                    "Answer",
                    subtitle: "Synthesized from the retrieved document evidence.",
                    systemImage: "quote.bubble.fill",
                    tint: GalaxyTheme.cometMint
                )

                ScrollView {
                    Text(model.questionAnswer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 260)
            }
        }
    }

    private var relevantDocumentsCard: some View {
        GlassCard(tint: GalaxyTheme.nebulaBlue) {
            VStack(alignment: .leading, spacing: 12) {
                GalaxySectionHeader(
                    "Most relevant documents",
                    subtitle: "Ranked by similarity to the question.",
                    systemImage: "scope",
                    tint: GalaxyTheme.nebulaBlue
                )

                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(model.questionTopPapers) { scored in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(scored.paper.title)
                                    .font(.subheadline.bold())
                                    .lineLimit(2)
                                Spacer()
                                GalaxyStatusPill(
                                    String(format: "%.3f", scored.score),
                                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                                    tint: GalaxyTheme.nebulaBlue
                                )
                            }
                            Text(scored.paper.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(4)
                        }
                        .padding(12)
                        .background(GalaxyTheme.nebulaBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(GalaxyTheme.nebulaBlue.opacity(0.18), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var evidenceCard: some View {
        GlassCard(tint: GalaxyTheme.solarGold) {
            DisclosureGroup {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(model.questionEvidence.prefix(12)) { ev in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ev.paperTitle)
                                .font(.subheadline.bold())
                                .lineLimit(2)
                            HStack(spacing: 8) {
                                GalaxyStatusPill(
                                    String(format: "Chunk %.3f", ev.score),
                                    systemImage: "number",
                                    tint: GalaxyTheme.solarGold
                                )
                                if let citation = ev.citationLabel {
                                    Text(citation)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Text(ev.chunk.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(6)
                                .textSelection(.enabled)
                        }
                        .padding(12)
                        .background(GalaxyTheme.solarGold.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(GalaxyTheme.solarGold.opacity(0.18), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 10)
            } label: {
                GalaxySectionHeader(
                    "Evidence (\(model.questionEvidence.count) chunks)",
                    subtitle: "Top retrieved source fragments behind the answer.",
                    systemImage: "text.magnifyingglass",
                    tint: GalaxyTheme.solarGold
                )
            }
        }
    }

    private func askCurrentQuestion() {
        let question = trimmedQuestion
        guard !question.isEmpty else { return }
        model.recordQuestionAsked(question)
        model.answerQuestion(question)
    }
}
