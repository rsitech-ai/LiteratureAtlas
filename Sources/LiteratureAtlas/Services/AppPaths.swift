import Foundation

enum AppPaths {
    static func repoRoot() -> URL {
        let fm = FileManager.default
        let env = ProcessInfo.processInfo.environment

        if let override = env["LITERATURE_ATLAS_REPO_ROOT"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let url = URL(fileURLWithPath: override, isDirectory: true)
            if looksLikeRepoRoot(url, fileManager: fm) { return url }
        }

        var candidates: [URL] = [
            URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true),
            Bundle.main.bundleURL
        ]

        if let executable = Bundle.main.executableURL {
            candidates.append(executable.deletingLastPathComponent())
        }

        for candidate in candidates {
            if let root = nearestRepoRoot(from: candidate, fileManager: fm) {
                return root
            }
        }

        return URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true)
    }

    static func outputRoot() -> URL {
        repoRoot().appendingPathComponent("Output", isDirectory: true)
    }

    static func promptsRoot() -> URL {
        repoRoot().appendingPathComponent("Prompts", isDirectory: true)
    }

    private static func nearestRepoRoot(from start: URL, fileManager fm: FileManager) -> URL? {
        var current = start.standardizedFileURL

        if current.pathExtension == "app" {
            current.deleteLastPathComponent()
        }

        while current.path != "/" {
            if looksLikeRepoRoot(current, fileManager: fm) {
                return current
            }
            current.deleteLastPathComponent()
        }

        return nil
    }

    private static func looksLikeRepoRoot(_ url: URL, fileManager fm: FileManager) -> Bool {
        fm.fileExists(atPath: url.appendingPathComponent("Package.swift").path)
            && fm.fileExists(atPath: url.appendingPathComponent("Sources/LiteratureAtlas").path)
    }
}
