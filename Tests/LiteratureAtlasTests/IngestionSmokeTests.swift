import Foundation
import XCTest
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
final class IngestionSmokeTests: XCTestCase {
    func testIngestsSampleFolderAndWritesArtifacts() async throws {
        let env = ProcessInfo.processInfo.environment

        guard let inputDir = env["LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR"], !inputDir.isEmpty else {
            throw XCTSkip("Set LITERATURE_ATLAS_INGEST_SMOKE_INPUT_DIR to run this smoke test.")
        }
        guard let outputRoot = env["LITERATURE_ATLAS_INGEST_SMOKE_OUTPUT_ROOT"], !outputRoot.isEmpty else {
            throw XCTSkip("Set LITERATURE_ATLAS_INGEST_SMOKE_OUTPUT_ROOT to run this smoke test.")
        }

        let expectedCount = Int(env["LITERATURE_ATLAS_INGEST_SMOKE_EXPECTED_COUNT"] ?? "") ?? 10
        let timeoutSeconds = Double(env["LITERATURE_ATLAS_INGEST_SMOKE_TIMEOUT_SEC"] ?? "") ?? 1200

        let inputURL = URL(fileURLWithPath: inputDir, isDirectory: true)
        let outputURL = URL(fileURLWithPath: outputRoot, isDirectory: true)

        let fm = FileManager.default
        var isDir: ObjCBool = false
        XCTAssertTrue(fm.fileExists(atPath: inputURL.path, isDirectory: &isDir) && isDir.boolValue, "Input dir missing: \(inputURL.path)")

        let inputPDFs = try fm.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { $0.pathExtension.lowercased() == "pdf" }
        XCTAssertEqual(inputPDFs.count, expectedCount, "Smoke input folder should contain exactly \(expectedCount) PDFs.")

        let model = await MainActor.run { AppModel(skipInitialLoad: true, customOutputRoot: outputURL) }
        await MainActor.run { model.ingestFolder(url: inputURL) }

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        var sawIngestionStart = false
        while Date() < deadline {
            let snapshot = await MainActor.run {
                (model.isIngesting, model.ingestionCompletedCount, model.ingestionTotalCount)
            }
            let currentlyIngesting = snapshot.0
            if currentlyIngesting {
                sawIngestionStart = true
            }
            if !currentlyIngesting && (sawIngestionStart || snapshot.1 > 0 || snapshot.2 > 0) {
                break
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        let finalSnapshot = await MainActor.run {
            (
                model.isIngesting,
                model.ingestionCompletedCount,
                model.ingestionTotalCount,
                model.papers.count,
                model.ingestionLog
            )
        }

        XCTAssertTrue(sawIngestionStart || finalSnapshot.1 > 0, "Ingestion never started.")
        XCTAssertFalse(finalSnapshot.0, "Ingestion did not finish before timeout.\n\(finalSnapshot.4)")
        XCTAssertEqual(finalSnapshot.2, expectedCount, "Ingestion total count mismatch.")
        XCTAssertEqual(finalSnapshot.1, expectedCount, "Completed ingestion count mismatch.")
        XCTAssertGreaterThanOrEqual(finalSnapshot.3, expectedCount, "Expected at least \(expectedCount) ingested papers.")

        await MainActor.run {
            model.testExportObsidianVaultArtifacts(force: true)
        }

        let paperDir = outputURL.appendingPathComponent("papers", isDirectory: true)
        let noteDir = outputURL.appendingPathComponent("obsidian/papers", isDirectory: true)
        let chunksURL = outputURL.appendingPathComponent("chunks/chunks.json", isDirectory: false)

        let jsonFiles = try fm.contentsOfDirectory(at: paperDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { $0.lastPathComponent.hasSuffix(".paper.json") }
        XCTAssertEqual(jsonFiles.count, expectedCount, "Unexpected number of generated .paper.json files.")

        let noteFiles = try fm.contentsOfDirectory(at: noteDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { $0.pathExtension.lowercased() == "md" }
        XCTAssertGreaterThanOrEqual(noteFiles.count, expectedCount, "Expected at least \(expectedCount) generated Obsidian notes.")

        XCTAssertTrue(fm.fileExists(atPath: chunksURL.path), "Missing chunks index file at \(chunksURL.path)")
        let chunkData = try Data(contentsOf: chunksURL)
        let chunkPayload = try JSONSerialization.jsonObject(with: chunkData, options: [])
        guard let chunkArray = chunkPayload as? [[String: Any]] else {
            XCTFail("chunks.json should decode to an array of objects")
            return
        }
        XCTAssertFalse(chunkArray.isEmpty, "Expected non-empty chunks.json after ingestion.")

        for jsonURL in jsonFiles {
            let data = try Data(contentsOf: jsonURL)
            let payload = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dict = payload as? [String: Any] else {
                XCTFail("Invalid JSON object in \(jsonURL.lastPathComponent)")
                continue
            }
            let summary = (dict["summary"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(summary.isEmpty, "Paper summary is empty in \(jsonURL.lastPathComponent)")

            let embedding = dict["embedding"] as? [Any] ?? []
            XCTAssertFalse(embedding.isEmpty, "Paper embedding is empty in \(jsonURL.lastPathComponent)")
        }
    }
}
