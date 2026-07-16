import Foundation
import Testing
@testable import LiteratureAtlas

#if os(macOS)
private final class FakeSecurityScopedBookmarkProvider: SecurityScopedBookmarkProviding {
    var stalePaths: Set<String> = []
    var allowsAccess = true
    private(set) var bookmarkCreationCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func makeBookmark(for url: URL) throws -> Data {
        bookmarkCreationCount += 1
        return Data(url.standardizedFileURL.path.utf8)
    }

    func resolveBookmark(_ data: Data) throws -> SecurityScopedBookmarkResolution {
        guard let path = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return SecurityScopedBookmarkResolution(
            url: URL(fileURLWithPath: path, isDirectory: true),
            isStale: stalePaths.contains(path)
        )
    }

    func startAccessing(_ url: URL) -> Bool {
        startCount += 1
        return allowsAccess
    }

    func stopAccessing(_ url: URL) {
        stopCount += 1
    }
}

@MainActor
@Suite("Source access bookmarks")
struct SourceAccessStoreTests {
    @Test("bookmark access survives store recreation and balances scope")
    func bookmarkAccessSurvivesStoreRecreation() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storageURL = temporaryRoot.appendingPathComponent("source-access.json")
        let selectedFolder = temporaryRoot.appendingPathComponent("Library", isDirectory: true)
        let sourceURL = selectedFolder.appendingPathComponent("Papers/sample.pdf")
        let provider = FakeSecurityScopedBookmarkProvider()

        let initialStore = SourceAccessStore(storageURL: storageURL, provider: provider)
        try initialStore.rememberFolder(selectedFolder)

        let relaunchedStore = SourceAccessStore(storageURL: storageURL, provider: provider)
        let openedPath = try relaunchedStore.withAccess(to: sourceURL) { resolvedURL in
            resolvedURL.standardizedFileURL.path
        }

        #expect(openedPath == sourceURL.standardizedFileURL.path)
        #expect(provider.startCount == 2)
        #expect(provider.stopCount == 2)
    }

    @Test("stale bookmarks are refreshed before access")
    func staleBookmarkIsRefreshed() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storageURL = temporaryRoot.appendingPathComponent("source-access.json")
        let selectedFolder = temporaryRoot.appendingPathComponent("Library", isDirectory: true)
        let sourceURL = selectedFolder.appendingPathComponent("sample.pdf")
        let provider = FakeSecurityScopedBookmarkProvider()
        let store = SourceAccessStore(storageURL: storageURL, provider: provider)
        try store.rememberFolder(selectedFolder)
        provider.stalePaths.insert(selectedFolder.standardizedFileURL.path)

        _ = try store.withAccess(to: sourceURL) { $0 }

        #expect(provider.bookmarkCreationCount == 2)
        #expect(provider.startCount == 2)
        #expect(provider.stopCount == 2)
    }

    @Test("bookmark creation requires and balances selected-folder scope")
    func bookmarkCreationRequiresScope() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let provider = FakeSecurityScopedBookmarkProvider()
        provider.allowsAccess = false
        let store = SourceAccessStore(
            storageURL: temporaryRoot.appendingPathComponent("source-access.json"),
            provider: provider
        )

        do {
            try store.rememberFolder(temporaryRoot.appendingPathComponent("Library", isDirectory: true))
            Issue.record("rememberFolder should fail when the selected folder scope cannot be activated")
        } catch SourceAccessStoreError.scopeDenied {
            #expect(provider.bookmarkCreationCount == 0)
            #expect(provider.startCount == 1)
            #expect(provider.stopCount == 0)
        }
    }

    @Test("async access holds the resolved scope until the operation finishes")
    func asyncAccessHoldsScope() async throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let selectedFolder = temporaryRoot.appendingPathComponent("Library", isDirectory: true)
        let provider = FakeSecurityScopedBookmarkProvider()
        let store = SourceAccessStore(
            storageURL: temporaryRoot.appendingPathComponent("source-access.json"),
            provider: provider
        )
        try store.rememberFolder(selectedFolder)

        try await store.withAccess(to: selectedFolder) { _ in
            await Task.yield()
            #expect(provider.startCount == 2)
            #expect(provider.stopCount == 1)
        }

        #expect(provider.startCount == 2)
        #expect(provider.stopCount == 2)
    }
}
#endif
