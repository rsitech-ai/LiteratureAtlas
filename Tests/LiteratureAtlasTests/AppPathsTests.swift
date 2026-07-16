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

    func testDistributedOutputRootUsesApplicationSupportContainer() {
        let applicationSupport = URL(fileURLWithPath: "/tmp/LiteratureAtlas-AppSupport", isDirectory: true)

        XCTAssertEqual(
            AppPaths.outputRoot(distributedBuild: true, applicationSupportRoot: applicationSupport),
            applicationSupport
                .appendingPathComponent("LiteratureAtlas", isDirectory: true)
                .appendingPathComponent("Output", isDirectory: true)
        )
    }

    func testDistributedPromptsRootUsesBundledResources() {
        let resources = URL(fileURLWithPath: "/tmp/LiteratureAtlas.app/Contents/Resources", isDirectory: true)

        XCTAssertEqual(
            AppPaths.promptsRoot(distributedBuild: true, bundleResourceRoot: resources),
            resources.appendingPathComponent("Prompts", isDirectory: true)
        )
    }

    func testDistributedBuildDisablesCheckoutOnlyRuntimeCapabilities() {
        let capabilities = AppRuntimeCapabilities(distributedBuild: true)

        XCTAssertFalse(capabilities.canRunRepositoryPython)
        XCTAssertFalse(capabilities.canLoadRepositoryRustLibrary)
        XCTAssertFalse(capabilities.canReadEnvironmentAPIKeys)
    }

    func testContributorBuildRetainsCheckoutRuntimeCapabilities() {
        let capabilities = AppRuntimeCapabilities(distributedBuild: false)

        XCTAssertTrue(capabilities.canRunRepositoryPython)
        XCTAssertTrue(capabilities.canLoadRepositoryRustLibrary)
        XCTAssertTrue(capabilities.canReadEnvironmentAPIKeys)
    }
}
