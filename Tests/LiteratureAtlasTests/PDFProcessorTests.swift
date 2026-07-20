import XCTest
@testable import LiteratureAtlas

final class PDFProcessorTests: XCTestCase {

    func testDetachedExtractionReceivesParentCancellation() async {
        let started = expectation(description: "detached extraction started")
        let extraction = Task {
            try await PDFProcessor.performCancellableDetachedExtraction {
                started.fulfill()
                while true {
                    try Task.checkCancellation()
                    Thread.sleep(forTimeInterval: 0.001)
                }
            }
        }

        await fulfillment(of: [started], timeout: 2)
        extraction.cancel()

        do {
            _ = try await extraction.value
            XCTFail("Cancellation should propagate into detached PDF work.")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testCancelledExtractionStopsBeforeOpeningTheFile() async {
        let missingURL = URL(fileURLWithPath: "/tmp/LiteratureAtlas-missing-cancelled.pdf")
        let (gate, continuation) = AsyncStream<Void>.makeStream()
        let extraction = Task {
            for await _ in gate { break }
            return try PDFProcessor().extractDocument(from: missingURL, documentID: UUID())
        }

        await Task.yield()
        extraction.cancel()
        continuation.yield(())
        continuation.finish()

        do {
            _ = try await extraction.value
            XCTFail("Cancelled extraction should not access the source file.")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testInferYearFromTextFindsFourDigitYear() {
        let text = "This study (2017) investigates..."
        let year = PDFProcessor().inferYear(fromText: text)
        XCTAssertEqual(year, 2017)
    }

    func testInferYearFromURLParsesArxivIDsAndAvoidsEmbeddedDigits() {
        // "2512.12039" is an arXiv YYMM.NNNNN identifier (Dec 2025).
        // Older logic incorrectly matched "2039" inside "12039".
        let url = URL(fileURLWithPath: "/tmp/2512.12039v1_Some_Paper_Title.pdf")
        let year = PDFProcessor().inferYear(from: url)
        XCTAssertEqual(year, 2025)
    }
}
