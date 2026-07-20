import XCTest
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
final class DocumentGraphExporterTests: XCTestCase {

    func testWritersReportFilesystemFailures() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not a directory".utf8).write(to: root)

        let graphWrite: () throws -> Void = {
            try DocumentGraphExporter.write(papers: [], clusters: [], claimEdges: [], outputRoot: root)
        }
        let compiledWrite: () throws -> Void = {
            try CompiledKnowledgeExporter.writeDocumentNotes(papers: [], outputRoot: root)
        }

        XCTAssertThrowsError(try graphWrite())
        XCTAssertThrowsError(try compiledWrite())
    }

    func testBuildSnapshotIncludesDocumentTopicEntityAndCompiledNodes() {
        let cluster = Cluster(
            id: 7,
            name: "Execution Alpha",
            metaSummary: "Cluster summary",
            tradingLens: nil,
            centroid: [1, 0],
            memberPaperIDs: [],
            layoutPosition: nil,
            resolutionK: 1,
            corpusVersion: "v1",
            subclusters: nil
        )

        let sharedEntity = "momentum"
        let p1Claim = PaperClaim(id: UUID(), paperID: UUID(), statement: "Improves execution quality.", assumptions: [], evaluation: nil, year: 2024, strength: 0.7)
        let p2Claim = PaperClaim(id: UUID(), paperID: UUID(), statement: "Extends execution quality.", assumptions: [], evaluation: nil, year: 2025, strength: 0.7)

        let p1 = makePaper(
            id: p1Claim.paperID,
            title: "Execution PDF",
            sourceKind: .pdf,
            clusterID: cluster.id,
            keywords: [sharedEntity, "liquidity"],
            compiledPath: "/tmp/compiled/execution-pdf.md",
            claim: p1Claim
        )
        let p2 = makePaper(
            id: p2Claim.paperID,
            title: "Execution Markdown",
            sourceKind: .markdown,
            clusterID: cluster.id,
            keywords: [sharedEntity, "latency"],
            compiledPath: "/tmp/compiled/execution-markdown.md",
            claim: p2Claim
        )

        let snapshot = DocumentGraphExporter.buildSnapshot(
            papers: [p1, p2],
            clusters: [cluster],
            claimEdges: [
                ClaimEdge(sourceClaimID: p1Claim.id, targetClaimID: p2Claim.id, kind: .supports, rationale: nil)
            ]
        )

        XCTAssertTrue(snapshot.nodes.contains { $0.kind == "document" && $0.title == "Execution PDF" })
        XCTAssertTrue(snapshot.nodes.contains { $0.kind == "topic" && $0.title == "Execution Alpha" })
        XCTAssertTrue(snapshot.nodes.contains { $0.kind == "compiled_note" && $0.path == "/tmp/compiled/execution-pdf.md" })
        XCTAssertTrue(snapshot.nodes.contains { $0.kind == "entity" && $0.title == sharedEntity })

        XCTAssertTrue(snapshot.edges.contains { $0.relation == "belongs_to" })
        XCTAssertTrue(snapshot.edges.contains { $0.relation == CompiledArtifactKind.documentNote.rawValue })
        XCTAssertTrue(snapshot.edges.contains { $0.relation == "mentions" && $0.target == "entity:\(sharedEntity)" })
        XCTAssertTrue(snapshot.edges.contains { $0.relation == ClaimRelationKind.supports.rawValue })
    }

    private func makePaper(
        id: UUID,
        title: String,
        sourceKind: SourceKind,
        clusterID: Int,
        keywords: [String],
        compiledPath: String,
        claim: PaperClaim
    ) -> Paper {
        let anchor = CitationAnchor(
            documentID: id,
            sourceKind: sourceKind,
            pageStart: sourceKind == .pdf ? 1 : nil,
            pageEnd: sourceKind == .pdf ? 1 : nil,
            headingPath: sourceKind == .markdown ? ["Intro"] : nil,
            lineStart: sourceKind == .markdown ? 1 : nil,
            lineEnd: sourceKind == .markdown ? 4 : nil,
            charStart: nil,
            charEnd: nil
        )
        return Paper(
            version: 2,
            sourceKind: sourceKind,
            filePath: "/tmp/\(title).\(sourceKind == .pdf ? "pdf" : "md")",
            sourceChecksum: "abc123",
            sourceModifiedAt: Date(),
            extractStatus: .extracted,
            id: id,
            originalFilename: "\(title).\(sourceKind == .pdf ? "pdf" : "md")",
            title: title,
            introSummary: nil,
            summary: "Summary for \(title)",
            methodSummary: nil,
            resultsSummary: nil,
            takeaways: ["Keep evidence grounded"],
            keywords: keywords,
            userNotes: nil,
            userTags: nil,
            readingStatus: .done,
            noteEmbedding: nil,
            userQuestions: nil,
            flashcards: nil,
            year: 2025,
            embedding: [1, 0],
            clusterIndex: clusterID,
            citationAnchors: [anchor],
            sections: [
                DocumentSection(id: UUID(), order: 0, title: "Intro", text: "Evidence", anchor: anchor)
            ],
            compiledArtifacts: [
                CompiledArtifactRef(kind: .documentNote, path: compiledPath, generatedAt: Date(), citations: [anchor])
            ],
            claims: [claim],
            assumptions: nil,
            evaluationContext: nil,
            methodPipeline: nil
        )
    }
}
