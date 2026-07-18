import XCTest
@testable import LiteratureAtlas

final class DisplayTextTests: XCTestCase {
    func testClusterNameReplacesGeneratedPlaceholderWithTruthfulLabel() {
        XCTAssertEqual(DisplayText.clusterName("Cluster 6"), "Unnamed topic")
        XCTAssertEqual(DisplayText.clusterName("  cluster 12  "), "Unnamed topic")
    }

    func testClusterNamePreservesDescriptiveName() {
        XCTAssertEqual(DisplayText.clusterName("**Causal inference**"), "Causal inference")
    }
}
