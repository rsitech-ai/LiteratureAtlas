import SwiftUI
import XCTest
@testable import LiteratureAtlas

final class ViewGeometryTests: XCTestCase {
    func testCompiledArtifactScanStopsAfterCancellation() async {
        let visits = LockedCounter()
        let sourceDate = Date()
        let papers = (0..<1_000).map { index in
            Paper(
                filePath: "/tmp/source-\(index).pdf",
                sourceModifiedAt: sourceDate,
                id: UUID(),
                originalFilename: "source-\(index).pdf",
                title: "Source \(index)",
                introSummary: nil,
                summary: "Summary",
                methodSummary: nil,
                resultsSummary: nil,
                takeaways: nil,
                keywords: nil,
                userNotes: nil,
                userTags: nil,
                readingStatus: nil,
                noteEmbedding: nil,
                userQuestions: nil,
                flashcards: nil,
                year: nil,
                embedding: [],
                clusterIndex: nil,
                compiledArtifacts: [
                    CompiledArtifactRef(
                        kind: .documentNote,
                        path: "/tmp/artifact-\(index).md",
                        generatedAt: nil,
                        citations: nil
                    )
                ]
            )
        }

        let scan = Task.detached {
            compiledArtifactStaleCount(papers) { _ in
                visits.increment()
                Thread.sleep(forTimeInterval: 0.005)
                return sourceDate
            }
        }

        while visits.value == 0 {
            await Task.yield()
        }
        scan.cancel()

        let result = await scan.value
        XCTAssertNil(result)
        XCTAssertLessThan(visits.value, papers.count)
    }

    func testSanitizedGeometrySizeRejectsNegativeAndNonFiniteDimensions() {
        XCTAssertEqual(
            sanitizedGeometrySize(CGSize(width: -1, height: CGFloat.infinity)),
            .zero
        )
        XCTAssertEqual(
            sanitizedGeometrySize(CGSize(width: 640, height: 480)),
            CGSize(width: 640, height: 480)
        )
    }

    func testGraphLayoutRadiusNeverProducesNegativeOrNonFiniteFrames() {
        XCTAssertEqual(graphLayoutRadius(size: CGSize(width: 100, height: 80), padding: 80), 0)
        XCTAssertEqual(graphLayoutRadius(size: CGSize(width: CGFloat.infinity, height: 200), padding: 80), 0)
        XCTAssertEqual(graphLayoutRadius(size: CGSize(width: 300, height: 300), padding: 80), 70)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = 0

    var value: Int {
        lock.withLock { storage }
    }

    func increment() {
        lock.withLock { storage += 1 }
    }
}
