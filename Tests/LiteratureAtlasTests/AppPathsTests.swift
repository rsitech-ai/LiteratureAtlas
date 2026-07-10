import XCTest
@testable import LiteratureAtlas

final class AppPathsTests: XCTestCase {
    func testRepoRootResolvesPackageRoot() {
        let root = AppPaths.repoRoot()
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path),
            "repoRoot should resolve to the SwiftPM package root"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources/LiteratureAtlas").path),
            "repoRoot should resolve to the LiteratureAtlas source root"
        )
    }

    func testOutputAndPromptsRootsUseRepoRoot() {
        let root = AppPaths.repoRoot()
        XCTAssertEqual(AppPaths.outputRoot(), root.appendingPathComponent("Output", isDirectory: true))
        XCTAssertEqual(AppPaths.promptsRoot(), root.appendingPathComponent("Prompts", isDirectory: true))
    }
}
