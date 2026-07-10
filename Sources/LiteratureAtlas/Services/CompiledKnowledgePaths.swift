import Foundation

enum CompiledKnowledgePaths {
    static func sanitizeFileName(_ value: String, maxLength: Int) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitized = value.components(separatedBy: invalid).joined(separator: "-")
        let collapsed = sanitized
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if collapsed.isEmpty {
            return "untitled"
        }
        if collapsed.count <= maxLength {
            return collapsed
        }
        return String(collapsed.prefix(maxLength))
    }

    static func documentURL(for paper: Paper, outputRoot: URL) -> URL {
        documentURL(
            title: paper.title.isEmpty ? paper.originalFilename : paper.title,
            documentID: paper.id,
            outputRoot: outputRoot
        )
    }

    static func documentURL(title: String, documentID: UUID, outputRoot: URL) -> URL {
        let fileName = documentFileName(title: title, documentID: documentID)
        return outputRoot
            .appendingPathComponent("compiled/documents", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    static func documentPath(for paper: Paper, outputRoot: URL) -> String {
        documentURL(for: paper, outputRoot: outputRoot).path
    }

    static func documentPath(title: String, documentID: UUID, outputRoot: URL) -> String {
        documentURL(title: title, documentID: documentID, outputRoot: outputRoot).path
    }

    static func documentFileName(title: String, documentID: UUID) -> String {
        let baseName = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "untitled" : title
        let safeName = sanitizeFileName(baseName, maxLength: 140)
        return "\(safeName) [\(documentID.uuidString)].md"
    }

    static func topicURL(for cluster: Cluster, outputRoot: URL) -> URL {
        let baseName = cluster.name.isEmpty ? "Cluster \(cluster.id)" : cluster.name
        let safeName = sanitizeFileName(baseName, maxLength: 140)
        return outputRoot
            .appendingPathComponent("compiled/topics", isDirectory: true)
            .appendingPathComponent("\(safeName) [cluster-\(cluster.id)].md")
    }

    static func entityURL(for entity: String, outputRoot: URL) -> URL {
        let safeName = sanitizeFileName(entity, maxLength: 120)
        return outputRoot
            .appendingPathComponent("compiled/entities", isDirectory: true)
            .appendingPathComponent("\(safeName).md")
    }
}
