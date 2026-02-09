import XCTest
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
final class AppModelChunkingTests: XCTestCase {

    func testChunkingRespectsMaxLengthAndOverlap() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }
        let lorem = String(repeating: "abcd ", count: 800) // 4000 chars

        let chunks = await MainActor.run {
            model.testChunkSegments(text: lorem, maxChars: 500, overlap: 50, maxChunks: 10)
        }

        XCTAssertFalse(chunks.isEmpty, "Expected chunks for non-empty text")
        XCTAssertLessThanOrEqual(chunks.count, 10, "Respects maxChunks")
        XCTAssertTrue(chunks.allSatisfy { $0.count <= 500 }, "Every chunk should stay within maxChars")

        if chunks.count >= 2 {
            let first = chunks[0]
            let second = chunks[1]
            // Overlap of at least the requested size, bounded by actual chunk sizes
            let overlap = min(50, min(first.count, second.count))
            let suffix = first.suffix(overlap)
            let prefix = second.prefix(overlap)
            XCTAssertEqual(suffix, prefix, "Chunks should overlap to avoid gaps")
        }
    }

    func testChunkingStopsWhenTextFitsSingleChunk() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }
        let shortText = "short text"

        let chunks = await MainActor.run {
            model.testChunkSegments(text: shortText, maxChars: 500, overlap: 50, maxChunks: 3)
        }

        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks.first, shortText)
    }

    func testChunkingClampsToMaxChunks() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }
        let text = String(repeating: "x", count: 10_000)

        let chunks = await MainActor.run {
            model.testChunkSegments(text: text, maxChars: 400, overlap: 0, maxChunks: 3)
        }

        XCTAssertEqual(chunks.count, 3, "Should stop at maxChunks even if more text remains")
    }

    func testChunkingStillProgressesWhenOverlapIsTooLarge() async {
        let model = await MainActor.run { AppModel(skipInitialLoad: true) }
        let text = (0..<30).map { "w\($0)" }.joined(separator: " ")

        let chunks = await MainActor.run {
            model.testChunkSegments(text: text, maxChars: 24, overlap: 24, maxChunks: 200)
        }

        XCTAssertFalse(chunks.isEmpty)
        XCTAssertGreaterThan(Set(chunks).count, 1, "Chunking should advance even when overlap >= maxChars")
        XCTAssertTrue(chunks.last?.contains("w29") == true, "Chunking should eventually reach the end of input text")
    }
}
