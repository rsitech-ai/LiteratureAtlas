import XCTest
import CryptoKit
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
final class AppModelTests: XCTestCase {
#if os(macOS)
    func testPythonRunnerDoesNotFallBackToGlobalInterpreter() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp.appendingPathComponent("Output")) }

        let result = model.testRunPython(arguments: ["--version"], cwd: tmp)

        switch result {
        case .success:
            XCTFail("A missing analytics/.venv must not fall back to a global Python")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("analytics/.venv"))
        }
    }
#endif

    func testCancelClusteringImmediatelyLeavesCancelableState() async {
        let model = await AppModel(skipInitialLoad: true)
        let papers = (0..<20).map { index in
            Paper(
                filePath: "paper-\(index)", id: UUID(), originalFilename: "paper-\(index).pdf",
                title: "Paper \(index)", introSummary: nil, summary: "summary",
                methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil,
                userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil,
                userQuestions: nil, flashcards: nil, year: nil,
                embedding: [Float(index), Float(index % 3)], clusterIndex: nil
            )
        }
        await MainActor.run {
            model.papers = papers
            model.clusters = [
                Cluster(
                    id: 7,
                    name: "Existing cluster",
                    metaSummary: "Previously valid state",
                    centroid: [1, 0],
                    memberPaperIDs: papers.map(\.id),
                    layoutPosition: nil,
                    resolutionK: 1,
                    corpusVersion: "existing",
                    subclusters: nil
                )
            ]
            model.selectedClusterIDs = [7]
            model.performClustering(k: 3)
            model.cancelClustering()
        }
        try? await Task.sleep(for: .milliseconds(100))
        await MainActor.run {
            XCTAssertFalse(model.isClustering)
            XCTAssertEqual(model.clusters.map(\.id), [7])
            XCTAssertEqual(model.selectedClusterIDs, [7])
            XCTAssertTrue(model.papers.allSatisfy { $0.clusterIndex == nil })
        }
    }

    func testCancelMultiScaleGalaxyStopsDetachedCompute() async {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let papers = (0..<5_000).map { index in
            Paper(
                filePath: "paper-\(index)", id: UUID(), originalFilename: "paper-\(index).pdf",
                title: "Paper \(index)", introSummary: nil, summary: "summary",
                methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil,
                userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil,
                userQuestions: nil, flashcards: nil, year: nil,
                embedding: (0..<32).map { Float((index + $0) % 17) }, clusterIndex: nil
            )
        }
        await MainActor.run { model.papers = papers }

        let galaxyTask = Task { await model.buildMultiScaleGalaxy() }
        var computeStarted = false
        for _ in 0..<500 {
            if await MainActor.run(body: { model.testHasActiveMultiScaleComputeTask }) {
                computeStarted = true
                break
            }
            try? await Task.sleep(for: .milliseconds(1))
        }
        XCTAssertTrue(computeStarted)

        await MainActor.run { model.cancelClustering() }
        await galaxyTask.value

        await MainActor.run {
            XCTAssertFalse(model.testHasActiveMultiScaleComputeTask)
            XCTAssertFalse(model.isClustering)
            XCTAssertTrue(model.megaClusters.isEmpty)
        }
    }


    func testFallbackEmbeddingUsesStableVersionedTokenBuckets() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }

        let embedding = await MainActor.run {
            model.testFallbackEmbedding(for: "alpha beta alpha", dimension: 512)
        }

        XCTAssertEqual(embedding.count, 512)
        XCTAssertEqual(embedding[43], Float(2 / sqrt(5.0)), accuracy: 0.000_001)
        XCTAssertEqual(embedding[167], Float(1 / sqrt(5.0)), accuracy: 0.000_001)
        XCTAssertEqual(
            embedding.enumerated().filter { $0.offset != 43 && $0.offset != 167 }.map { $0.element },
            Array(repeating: 0, count: 510)
        )
    }

    func testUpsertReplacesByFilePath() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }

        await MainActor.run {
            model.papers = []
        }

        let p1 = Paper(
            version: 1,
            filePath: "/tmp/sample.pdf",
            id: UUID(),
            originalFilename: "sample.pdf",
            title: "Title 1",
            introSummary: nil,
            summary: "Summary one",
            methodSummary: nil,
            resultsSummary: nil,
            takeaways: nil,
            keywords: ["a"],
            userNotes: nil,
            userTags: nil,
            readingStatus: nil,
            noteEmbedding: nil,
            userQuestions: nil,
            flashcards: nil,
            year: nil,
            embedding: [1, 0],
            clusterIndex: nil
        )

        let p2 = Paper(
            version: 1,
            filePath: "/tmp/sample.pdf",
            id: UUID(),
            originalFilename: "sample.pdf",
            title: "Title 2",
            introSummary: nil,
            summary: "Summary two",
            methodSummary: nil,
            resultsSummary: nil,
            takeaways: nil,
            keywords: ["b"],
            userNotes: nil,
            userTags: nil,
            readingStatus: nil,
            noteEmbedding: nil,
            userQuestions: nil,
            flashcards: nil,
            year: nil,
            embedding: [0, 1],
            clusterIndex: nil
        )

        await MainActor.run {
            model.testUpsert(p1)
            model.testUpsert(p2)
        }

        await MainActor.run {
            XCTAssertEqual(model.papers.count, 1)
            XCTAssertEqual(model.papers.first?.title, "Title 2")
            XCTAssertEqual(model.papers.first?.summary, "Summary two")
        }
    }

    func testClusteringAssignsClusters() async {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }

        let papers: [Paper] = [
            Paper(version: 1, filePath: "a", id: UUID(), originalFilename: "a.pdf", title: "A", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil, embedding: [1, 0], clusterIndex: nil),
            Paper(version: 1, filePath: "b", id: UUID(), originalFilename: "b.pdf", title: "B", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil, embedding: [0, 1], clusterIndex: nil),
            Paper(version: 1, filePath: "c", id: UUID(), originalFilename: "c.pdf", title: "C", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil, embedding: [0.9, 0.1], clusterIndex: nil)
        ]

        await MainActor.run {
            model.papers = papers
        }

        await model.testRunClustering(k: 2)

        await MainActor.run {
            XCTAssertEqual(model.clusters.count, 2)
            XCTAssertTrue(model.papers.allSatisfy { $0.clusterIndex != nil })
            XCTAssertTrue(model.explorationPapers.allSatisfy { $0.clusterIndex != nil })
        }
    }

    func testExplorationPapersInClusterRespectsMembershipAndYearFilter() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }

        let p1 = Paper(version: 1, filePath: "a", id: UUID(), originalFilename: "a.pdf", title: "Alpha", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: ["x"], userNotes: nil, userTags: nil, readingStatus: .unread, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: 2010, embedding: [1, 0], clusterIndex: 1)
        let p2 = Paper(version: 1, filePath: "b", id: UUID(), originalFilename: "b.pdf", title: "Beta", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: ["y"], userNotes: nil, userTags: nil, readingStatus: .done, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: 2020, embedding: [0, 1], clusterIndex: 999)
        let p3 = Paper(version: 1, filePath: "c", id: UUID(), originalFilename: "c.pdf", title: "Gamma", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: ["z"], userNotes: nil, userTags: nil, readingStatus: .unread, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: 2015, embedding: [0.9, 0.1], clusterIndex: nil)

        await MainActor.run {
            model.papers = [p1, p2, p3]
        }

        let cluster = Cluster(id: 42, name: "C", metaSummary: "", centroid: [0, 0], memberPaperIDs: [p2.id, p3.id], layoutPosition: nil, resolutionK: 1, corpusVersion: "v", subclusters: nil)

        let all = await MainActor.run { model.explorationPapers(in: cluster).map(\.id) }
        XCTAssertEqual(Set(all), Set([p2.id, p3.id]))

        await MainActor.run {
            model.yearFilterEnabled = true
            model.yearFilterStart = 2020
            model.yearFilterEnd = 2020
        }

        let filtered = await MainActor.run { model.explorationPapers(in: cluster).map(\.id) }
        XCTAssertEqual(filtered, [p2.id])
    }

    func testSourceKindCountsReflectMixedCorpus() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }

        let pdf = Paper(version: 1, sourceKind: .pdf, filePath: "a", id: UUID(), originalFilename: "a.pdf", title: "PDF", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: ["x"], userNotes: nil, userTags: nil, readingStatus: .unread, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: 2020, embedding: [1, 0], clusterIndex: nil)
        let markdown = Paper(version: 1, sourceKind: .markdown, filePath: "b", id: UUID(), originalFilename: "b.md", title: "MD", introSummary: nil, summary: "s", methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: ["y"], userNotes: nil, userTags: nil, readingStatus: .done, noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: 2021, embedding: [0, 1], clusterIndex: nil)

        await MainActor.run {
            model.papers = [pdf, markdown]
        }

        let counts = await MainActor.run { model.sourceKindCounts }
        XCTAssertEqual(counts[.pdf], 1)
        XCTAssertEqual(counts[.markdown], 1)
    }

    func testUserEventsPersistWithoutRawQuestionText() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }

        await MainActor.run {
            model.recordQuestionAsked("Test question?")
        }

        let logURL = tmp.appendingPathComponent("analytics/user_events.jsonl")
        let contents = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("\"event_type\":\"qa_question\""))
        XCTAssertTrue(contents.contains("\"question_length\":14"))
        XCTAssertFalse(contents.contains("Test question?"))
        XCTAssertFalse(contents.contains("\"q\""))
    }

    func testCreateEmptyStrategyProjectDoesNotPublishWhenPersistenceFails() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let strategiesDirectory = tmp.appendingPathComponent("strategies", isDirectory: true)
        try FileManager.default.removeItem(at: strategiesDirectory)
        try Data("not a directory".utf8).write(to: strategiesDirectory)

        let created = await MainActor.run {
            model.createEmptyStrategyProject()
        }

        await MainActor.run {
            XCTAssertNil(created)
            XCTAssertTrue(model.strategyProjects.isEmpty)
            XCTAssertNotNil(model.persistenceError)
        }
    }

    func testUpdateStrategyProjectDoesNotReplacePublishedDraftWhenPersistenceFails() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let original = StrategyProject(title: "Saved title")
        await MainActor.run { model.strategyProjects = [original] }

        let strategiesDirectory = tmp.appendingPathComponent("strategies", isDirectory: true)
        try FileManager.default.removeItem(at: strategiesDirectory)
        try Data("not a directory".utf8).write(to: strategiesDirectory)
        var draft = original
        draft.title = "Unsaved edit"

        let saved = await MainActor.run { model.updateStrategyProject(draft) }

        await MainActor.run {
            XCTAssertFalse(saved)
            XCTAssertEqual(model.strategyProjects.first?.title, "Saved title")
            XCTAssertNotNil(model.persistenceError)
        }
    }

    func testDeleteStrategyProjectKeepsCanonicalProjectWhenNotesCannotBeInspected() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let created = await MainActor.run { model.createEmptyStrategyProject(title: "Keep me") }
        let project = try XCTUnwrap(created)
        let strategiesDirectory = tmp.appendingPathComponent("strategies", isDirectory: true)
        let canonicalFiles = try FileManager.default.contentsOfDirectory(
            at: strategiesDirectory,
            includingPropertiesForKeys: nil
        )
        XCTAssertEqual(canonicalFiles.count, 1)

        let notesDirectory = tmp
            .appendingPathComponent("obsidian", isDirectory: true)
            .appendingPathComponent("strategies", isDirectory: true)
        try FileManager.default.removeItem(at: notesDirectory)
        try Data("not a directory".utf8).write(to: notesDirectory)

        let deleted = await MainActor.run { model.deleteStrategyProject(project.id) }

        await MainActor.run {
            XCTAssertFalse(deleted)
            XCTAssertEqual(model.strategyProjects.map(\.id), [project.id])
            XCTAssertNotNil(model.persistenceError)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: canonicalFiles[0].path))
    }

    func testFailedCanonicalPaperWritePublishesNeitherPaperNorChunks() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let paper = Paper(
            filePath: "/tmp/paper.md", id: UUID(), originalFilename: "paper.md",
            title: "Transactional paper", introSummary: nil, summary: "Summary",
            methodSummary: nil, resultsSummary: nil, takeaways: nil, keywords: nil,
            userNotes: nil, userTags: nil, readingStatus: nil, noteEmbedding: nil,
            userQuestions: nil, flashcards: nil, year: nil, embedding: [1, 0], clusterIndex: nil
        )
        let chunk = PaperChunk(
            id: UUID(), paperID: paper.id, text: "Chunk", embedding: [1, 0],
            order: 0, pageHint: nil, citationAnchor: nil
        )
        let papersDirectory = tmp.appendingPathComponent("papers", isDirectory: true)
        try FileManager.default.removeItem(at: papersDirectory)
        try Data("not a directory".utf8).write(to: papersDirectory)

        let failed = await MainActor.run { () -> Bool in
            do {
                try model.testPersistAndPublishIngestedPaper(paper, chunks: [chunk])
                return false
            } catch {
                return true
            }
        }

        XCTAssertTrue(failed)
        await MainActor.run {
            XCTAssertTrue(model.papers.isEmpty)
            XCTAssertTrue(model.paperChunks.isEmpty)
        }
    }

    func testFailedChunkIndexWritePublishesNeitherPaperNorChunks() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let paper = Paper(
            filePath: "/tmp/chunk-failure.md", id: UUID(), originalFilename: "chunk-failure.md",
            title: "Chunk failure", introSummary: nil, summary: "Summary", methodSummary: nil,
            resultsSummary: nil, takeaways: nil, keywords: nil, userNotes: nil, userTags: nil,
            readingStatus: nil, noteEmbedding: nil, userQuestions: nil, flashcards: nil,
            year: nil, embedding: [1, 0], clusterIndex: nil
        )
        let chunk = PaperChunk(
            id: UUID(), paperID: paper.id, text: "Chunk", embedding: [1, 0],
            order: 0, pageHint: nil, citationAnchor: nil
        )
        let chunksDirectory = tmp.appendingPathComponent("chunks", isDirectory: true)
        try FileManager.default.removeItem(at: chunksDirectory)
        try Data("not a directory".utf8).write(to: chunksDirectory)

        let failed = await MainActor.run { () -> Bool in
            do {
                try model.testPersistAndPublishIngestedPaper(paper, chunks: [chunk])
                return false
            } catch {
                return true
            }
        }

        XCTAssertTrue(failed)
        await MainActor.run {
            XCTAssertTrue(model.papers.isEmpty)
            XCTAssertTrue(model.paperChunks.isEmpty)
        }
        let paperFiles = try FileManager.default.contentsOfDirectory(
            at: tmp.appendingPathComponent("papers", isDirectory: true),
            includingPropertiesForKeys: nil
        )
        XCTAssertTrue(paperFiles.isEmpty)
    }

    func testSourceChecksumPreventsFalseSkipWhenTimestampIsPreserved() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let source = tmp.appendingPathComponent("paper.md")
        try Data("original".utf8).write(to: source)
        let checksum = SHA256.hash(data: Data("original".utf8)).map { String(format: "%02x", $0) }.joined()
        var paper = Paper(
            filePath: source.path, sourceChecksum: checksum, id: UUID(), originalFilename: "paper.md",
            title: "Paper", introSummary: nil, summary: "Summary", methodSummary: nil,
            resultsSummary: nil, takeaways: nil, keywords: nil, userNotes: nil, userTags: nil,
            readingStatus: nil, noteEmbedding: nil, userQuestions: nil, flashcards: nil,
            year: nil, embedding: [1, 0], clusterIndex: nil
        )
        paper.ingestedAt = Date()
        try Data("changed".utf8).write(to: source)
        try FileManager.default.setAttributes([.modificationDate: Date.distantPast], ofItemAtPath: source.path)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp.appendingPathComponent("Output")) }

        let shouldSkip = await model.testShouldSkipSource(sourceURL: source, existingPaper: paper)

        XCTAssertFalse(shouldSkip)
    }

    func testSourceChecksumCancellationStopsChunkedHashingPromptly() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("large-paper.pdf")
        try Data(repeating: 0x41, count: 32 * 1_024 * 1_024).write(to: source)
        let model = await MainActor.run {
            AppModel(skipInitialLoad: true, customOutputRoot: tmp.appendingPathComponent("Output"))
        }
        let checksumTask = Task {
            await model.testSourceChecksum(sourceURL: source, chunkSize: 1)
        }

        try await Task.sleep(for: .milliseconds(20))
        let cancellationStart = ContinuousClock.now
        checksumTask.cancel()
        let checksum = await checksumTask.value
        let cancellationLatency = ContinuousClock.now - cancellationStart

        XCTAssertNil(checksum)
        XCTAssertLessThan(cancellationLatency, .seconds(1))
    }

    func testLoadingSavedPapersDeduplicatesPaperIDs() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let papersDirectory = tmp.appendingPathComponent("papers", isDirectory: true)
        let sharedID = UUID()
        let older = Paper(
            filePath: "/tmp/older.pdf", id: sharedID, originalFilename: "older.pdf", title: "Older",
            introSummary: nil, summary: "old", methodSummary: nil, resultsSummary: nil,
            takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil,
            noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil,
            embedding: [1, 0], clusterIndex: nil
        )
        var newer = older
        newer.filePath = "/tmp/newer.pdf"
        newer.originalFilename = "newer.pdf"
        newer.title = "Newer"
        newer.summary = "new"
        let encoder = JSONEncoder()
        let olderURL = papersDirectory.appendingPathComponent("older.paper.json")
        let newerURL = papersDirectory.appendingPathComponent("newer.paper.json")
        try encoder.encode(older).write(to: olderURL)
        try encoder.encode(newer).write(to: newerURL)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: olderURL.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2)], ofItemAtPath: newerURL.path)

        await model.testLoadSavedPapers()

        await MainActor.run {
            XCTAssertEqual(model.papers.count, 1)
            XCTAssertEqual(model.papers.first?.title, "Newer")
        }
    }

    func testLoadingSavedPapersDerivesDimensionAfterDiscardingStaleDuplicate() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let papersDirectory = tmp.appendingPathComponent("papers", isDirectory: true)
        let sharedID = UUID()
        let stale = Paper(
            filePath: "/tmp/stale.pdf", id: sharedID, originalFilename: "stale.pdf", title: "Stale",
            introSummary: nil, summary: "stale", methodSummary: nil, resultsSummary: nil,
            takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil,
            noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil,
            embedding: [1, 0], clusterIndex: nil
        )
        var fresh = stale
        fresh.filePath = "/tmp/fresh.pdf"
        fresh.originalFilename = "fresh.pdf"
        fresh.title = "Fresh"
        fresh.embedding = [1, 0, 0]
        var peer = stale
        peer.id = UUID()
        peer.filePath = "/tmp/peer.pdf"
        peer.originalFilename = "peer.pdf"
        peer.title = "Peer"
        peer.embedding = [0, 1, 0]
        let encoder = JSONEncoder()
        let staleURL = papersDirectory.appendingPathComponent("a-stale.paper.json")
        let freshURL = papersDirectory.appendingPathComponent("b-fresh.paper.json")
        let peerURL = papersDirectory.appendingPathComponent("c-peer.paper.json")
        try encoder.encode(stale).write(to: staleURL)
        try encoder.encode(fresh).write(to: freshURL)
        try encoder.encode(peer).write(to: peerURL)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)], ofItemAtPath: staleURL.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2)], ofItemAtPath: freshURL.path)

        await model.testLoadSavedPapers()

        await MainActor.run {
            XCTAssertEqual(model.papers.count, 2)
            XCTAssertTrue(model.papers.allSatisfy { $0.embedding.count == 3 })
            XCTAssertEqual(model.papers.first(where: { $0.id == sharedID })?.title, "Fresh")
        }
    }

    func testOpenSourceDocumentSurfacesPlatformFailureAfterBookmarkResolution() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let selectedFolder = tmp.appendingPathComponent("Library", isDirectory: true)
        let sourceURL = selectedFolder.appendingPathComponent("paper.pdf")
        let provider = FakeSecurityScopedBookmarkProvider()
        let store = await MainActor.run {
            SourceAccessStore(
                storageURL: tmp.appendingPathComponent("source-access.json"),
                provider: provider
            )
        }
        try await MainActor.run { try store.rememberFolder(selectedFolder) }
        let model = await MainActor.run {
            AppModel(
                skipInitialLoad: true,
                customOutputRoot: tmp.appendingPathComponent("Output"),
                sourceAccessStore: store,
                sourceDocumentOpener: { _ in false }
            )
        }
        let paper = Paper(
            filePath: sourceURL.path, id: UUID(), originalFilename: "paper.pdf", title: "Paper",
            introSummary: nil, summary: "Summary", methodSummary: nil, resultsSummary: nil,
            takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil,
            noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil,
            embedding: [1, 0], clusterIndex: nil
        )

        await MainActor.run {
            model.papers = [paper]
            model.openSourceDocument(for: paper.id)
            XCTAssertNotNil(model.sourceAccessError)
        }
        XCTAssertEqual(provider.startCount, 2)
        XCTAssertEqual(provider.stopCount, 2)
    }

    func testPinRollbackWhenGalaxySnapshotCannotBePersisted() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let cluster = Cluster(
            id: 7, name: "Original", metaSummary: "Summary", centroid: [1, 0],
            memberPaperIDs: [], layoutPosition: nil, resolutionK: 1,
            corpusVersion: "v1", subclusters: nil
        )
        try replaceDirectoryWithFile(tmp.appendingPathComponent("clusters", isDirectory: true))

        let saved = await MainActor.run { () -> Bool in
            model.megaClusters = [cluster]
            return model.toggleGalaxyPin(clusterID: cluster.id)
        }

        await MainActor.run {
            XCTAssertFalse(saved)
            XCTAssertFalse(model.pinnedClusterIDs.contains(cluster.id))
            XCTAssertNotNil(model.persistenceError)
        }
    }

    func testRenameRollbackWhenGalaxySnapshotCannotBePersisted() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let cluster = Cluster(
            id: 7, name: "Original", metaSummary: "Summary", centroid: [1, 0],
            memberPaperIDs: [], layoutPosition: nil, resolutionK: 1,
            corpusVersion: "v1", subclusters: nil
        )
        try replaceDirectoryWithFile(tmp.appendingPathComponent("clusters", isDirectory: true))

        let saved = await MainActor.run { () -> Bool in
            model.megaClusters = [cluster]
            return model.renameGalaxyCluster(clusterID: cluster.id, name: "Unsaved", metaSummary: nil)
        }

        await MainActor.run {
            XCTAssertFalse(saved)
            XCTAssertEqual(model.megaClusters.first?.name, "Original")
            XCTAssertNil(model.clusterNameSources[cluster.id])
            XCTAssertNotNil(model.persistenceError)
        }
    }

    func testFlashcardReviewRollbackWhenPaperCannotBePersisted() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let cardID = UUID()
        let paper = Paper(
            filePath: "/tmp/paper.pdf", id: UUID(), originalFilename: "paper.pdf", title: "Paper",
            introSummary: nil, summary: "Summary", methodSummary: nil, resultsSummary: nil,
            takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: .done,
            noteEmbedding: nil, userQuestions: nil,
            flashcards: [Flashcard(id: cardID, question: "Q?", answer: "A.", lastReviewedAt: nil, reviewCount: nil)],
            year: nil, embedding: [1, 0], clusterIndex: nil
        )
        try replaceDirectoryWithFile(tmp.appendingPathComponent("papers", isDirectory: true))

        let saved = await MainActor.run { () -> Bool in
            model.papers = [paper]
            return model.markFlashcardReviewed(paperID: paper.id, cardID: cardID)
        }

        await MainActor.run {
            XCTAssertFalse(saved)
            XCTAssertNil(model.papers.first?.flashcards?.first?.lastReviewedAt)
            XCTAssertNil(model.papers.first?.flashcards?.first?.reviewCount)
            XCTAssertNotNil(model.persistenceError)
        }
    }

    func testKMeansStopsWhenCancellationIsRequested() {
        let vectors = (0..<200).map { index in
            (0..<32).map { dimension in Float((index + dimension) % 11) }
        }
        var checks = 0

        let result = KMeans.cluster(vectors: vectors, k: 8, iterations: 100) {
            checks += 1
            return checks >= 8
        }

        XCTAssertNil(result)
        XCTAssertEqual(checks, 8)
    }

    func testForceLayoutStopsWhenCancellationIsRequested() {
        let vectors = (0..<80).map { index in
            (0..<16).map { dimension in Float((index + dimension) % 7) }
        }
        var checks = 0

        let result = ForceLayout.compute(for: vectors) {
            checks += 1
            return checks >= 8
        }

        XCTAssertNil(result)
        XCTAssertEqual(checks, 8)
    }

    func testReloadAnalyticsRejectsMismatchedCanonicalPaperCount() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let paper = makeAnalyticsTestPaper(id: UUID())
        try writeAnalyticsPayload(
            [
                "generated_at": "2025-01-02T03:04:05Z",
                "paper_count": 2,
                "vector_dim": 2,
            ],
            to: tmp
        )

        await MainActor.run {
            model.papers = [paper]
            model.reloadAnalyticsSummary()
            XCTAssertNil(model.analyticsSummary)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("stale") == true)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("rebuild") == true)
        }
    }

    func testReloadAnalyticsRejectsPaperMetricsOutsideCanonicalCorpus() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let paper = makeAnalyticsTestPaper(id: UUID())
        let unknownID = UUID()
        let metric: [String: Any] = [
            "paper_id": unknownID.uuidString,
            "nov_cluster": 0.0, "nov_global": 0.0, "nov_directional": 0.0,
            "nov_combinatorial": 0.0, "novelty_uncertainty": 0.0, "z_novelty": 0.0,
            "consensus_struct": 0.0, "consensus_claim": 0.0, "consensus_temporal": 0.0,
            "consensus_total": 0.0, "z_consensus": 0.0, "consensus_uncertainty": 0.0,
            "influence_abs": 0.0, "influence_pos": 0.0, "influence_neg": 0.0,
            "drift_contrib": 0.0, "role_source": 0.0, "role_bridge": 0.0, "role_sink": 0.0,
        ]
        try writeAnalyticsPayload(
            [
                "generated_at": "2025-01-02T03:04:05Z",
                "paper_count": 1,
                "vector_dim": 2,
                "paper_metrics": [metric],
            ],
            to: tmp
        )

        await MainActor.run {
            model.papers = [paper]
            model.reloadAnalyticsSummary()
            XCTAssertNil(model.analyticsSummary)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("stale") == true)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("rebuild") == true)
        }
    }

    func testReloadAnalyticsRejectsNoveltyOutsideCanonicalCorpusWhenPaperMetricsAreEmpty() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }
        let paper = makeAnalyticsTestPaper(id: UUID())
        let unknownID = UUID()
        try writeAnalyticsPayload(
            [
                "generated_at": "2025-01-02T03:04:05Z",
                "paper_count": 1,
                "vector_dim": 2,
                "novelty": [[
                    "paper_id": unknownID.uuidString,
                    "cluster_id": 0,
                    "novelty": 0.5,
                ]],
            ],
            to: tmp
        )

        await MainActor.run {
            model.papers = [paper]
            model.reloadAnalyticsSummary()
            XCTAssertNil(model.analyticsSummary)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("stale") == true)
            XCTAssertTrue(model.analyticsLoadError?.localizedCaseInsensitiveContains("rebuild") == true)
        }
    }

    func testObsidianNoteLookupUsesCacheAfterInitialIndexing() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let noteDirectory = tmp.appendingPathComponent("obsidian/papers", isDirectory: true)
        try FileManager.default.createDirectory(at: noteDirectory, withIntermediateDirectories: true)
        let paperID = UUID()
        let noteURL = noteDirectory.appendingPathComponent("Paper [\(paperID.uuidString.uppercased())].md")
        try Data("# Note".utf8).write(to: noteURL)
        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: tmp) }

        try FileManager.default.removeItem(at: noteDirectory)
        try Data("not a directory".utf8).write(to: noteDirectory)

        let resolved = await MainActor.run { model.obsidianNoteURL(for: paperID) }

        XCTAssertEqual(resolved?.lastPathComponent, noteURL.lastPathComponent)
        XCTAssertEqual(resolved?.deletingLastPathComponent().lastPathComponent, "papers")
    }

    private func replaceDirectoryWithFile(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
        try Data("not a directory".utf8).write(to: url)
    }

    private func makeAnalyticsTestPaper(id: UUID) -> Paper {
        Paper(
            filePath: "/tmp/\(id.uuidString).pdf", id: id, originalFilename: "paper.pdf", title: "Paper",
            introSummary: nil, summary: "Summary", methodSummary: nil, resultsSummary: nil,
            takeaways: nil, keywords: nil, userNotes: nil, userTags: nil, readingStatus: nil,
            noteEmbedding: nil, userQuestions: nil, flashcards: nil, year: nil,
            embedding: [1, 0], clusterIndex: nil
        )
    }

    private func writeAnalyticsPayload(_ payload: [String: Any], to outputRoot: URL) throws {
        let analyticsURL = outputRoot.appendingPathComponent("analytics/analytics.json")
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: analyticsURL, options: .atomic)
    }
}
