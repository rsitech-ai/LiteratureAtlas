import XCTest
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
final class MarkdownProcessorTests: XCTestCase {

    func testExtractBuildsHeadingAnchorsAndKeywords() throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let fileURL = tmpDir.appendingPathComponent("sample.md")
        let documentID = UUID()

        let markdown = """
        ---
        title: Atlas Corpus
        year: 2026
        ---
        # Intro
        Alpha evidence line.
        ## Methods
        Beta method detail.
        """
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = try MarkdownProcessor().extract(from: fileURL, documentID: documentID)

        XCTAssertEqual(result.title, "Atlas Corpus")
        XCTAssertEqual(result.year, 2026)
        XCTAssertEqual(result.sections.count, 2)
        XCTAssertEqual(result.sections[0].anchor.sourceKind, .markdown)
        XCTAssertEqual(result.sections[0].anchor.lineStart, 5)
        XCTAssertEqual(result.sections[0].anchor.lineEnd, 6)
        XCTAssertEqual(result.sections[0].anchor.headingPath ?? [], ["Intro"])
        XCTAssertEqual(result.sections[1].anchor.headingPath ?? [], ["Intro", "Methods"])
        XCTAssertEqual(result.sections[1].anchor.lineStart, 7)
        XCTAssertEqual(result.sections[1].anchor.lineEnd, 8)
        XCTAssertTrue(result.text.contains("Alpha evidence line."))
        XCTAssertTrue(result.keywords.contains("atlas"))
    }

    func testExtractFallsBackToHeadingTitleWithoutFrontmatter() throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let fileURL = tmpDir.appendingPathComponent("fallback-title.md")

        let markdown = """
        # Practical Atlas Notes
        Evidence starts here.
        """
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = try MarkdownProcessor().extract(from: fileURL, documentID: UUID())

        XCTAssertEqual(result.title, "Practical Atlas Notes")
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections[0].anchor.headingPath ?? [], ["Practical Atlas Notes"])
    }
}
