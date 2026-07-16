import Foundation

#if os(macOS)
struct SecurityScopedBookmarkResolution: Equatable {
    let url: URL
    let isStale: Bool
}

protocol SecurityScopedBookmarkProviding {
    func makeBookmark(for url: URL) throws -> Data
    func resolveBookmark(_ data: Data) throws -> SecurityScopedBookmarkResolution
    func startAccessing(_ url: URL) -> Bool
    func stopAccessing(_ url: URL)
}

struct FoundationSecurityScopedBookmarkProvider: SecurityScopedBookmarkProviding {
    func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolveBookmark(_ data: Data) throws -> SecurityScopedBookmarkResolution {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return SecurityScopedBookmarkResolution(url: url, isStale: isStale)
    }

    func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}

enum SourceAccessStoreError: LocalizedError {
    case noBookmark(URL)
    case scopeDenied(URL)

    var errorDescription: String? {
        switch self {
        case .noBookmark(let url):
            return "Access to \(url.lastPathComponent) expired. Select its source folder again."
        case .scopeDenied(let url):
            return "macOS denied access to \(url.lastPathComponent). Select its source folder again."
        }
    }
}

final class SourceAccessStore {
    private struct Record: Codable, Equatable {
        let selectedPath: String
        var bookmark: Data
    }

    private let storageURL: URL
    private let provider: any SecurityScopedBookmarkProviding
    private var records: [Record]

    init(
        storageURL: URL,
        provider: any SecurityScopedBookmarkProviding = FoundationSecurityScopedBookmarkProvider()
    ) {
        self.storageURL = storageURL
        self.provider = provider
        records = Self.loadRecords(from: storageURL)
    }

    func rememberFolder(_ folderURL: URL) throws {
        let normalizedURL = folderURL.standardizedFileURL
        let bookmark = try provider.makeBookmark(for: normalizedURL)
        let record = Record(selectedPath: normalizedURL.path, bookmark: bookmark)
        if let index = records.firstIndex(where: { $0.selectedPath == record.selectedPath }) {
            records[index] = record
        } else {
            records.append(record)
        }
        try persist()
    }

    func withAccess<T>(to sourceURL: URL, operation: (URL) throws -> T) throws -> T {
        let normalizedSource = sourceURL.standardizedFileURL
        guard let recordIndex = matchingRecordIndex(for: normalizedSource) else {
            throw SourceAccessStoreError.noBookmark(normalizedSource)
        }

        let record = records[recordIndex]
        let resolution = try provider.resolveBookmark(record.bookmark)
        let selectedRoot = URL(fileURLWithPath: record.selectedPath, isDirectory: true)
        let relativePath = normalizedSource.path.dropFirst(selectedRoot.path.count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let resolvedSource = relativePath.isEmpty
            ? resolution.url
            : resolution.url.appendingPathComponent(relativePath)

        if resolution.isStale {
            records[recordIndex].bookmark = try provider.makeBookmark(for: resolution.url)
            try persist()
        }

        guard provider.startAccessing(resolution.url) else {
            throw SourceAccessStoreError.scopeDenied(normalizedSource)
        }
        defer { provider.stopAccessing(resolution.url) }
        return try operation(resolvedSource)
    }

    private func matchingRecordIndex(for sourceURL: URL) -> Int? {
        records.indices
            .filter { index in
                let root = records[index].selectedPath
                return sourceURL.path == root || sourceURL.path.hasPrefix(root + "/")
            }
            .max { records[$0].selectedPath.count < records[$1].selectedPath.count }
    }

    private func persist() throws {
        try FileManager.default.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(records).write(to: storageURL, options: .atomic)
    }

    private static func loadRecords(from storageURL: URL) -> [Record] {
        guard let data = try? Data(contentsOf: storageURL),
              let records = try? JSONDecoder().decode([Record].self, from: data) else {
            return []
        }
        return records
    }
}
#endif
