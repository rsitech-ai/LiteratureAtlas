import CryptoKit
import Foundation

struct MarkdownExtractionResult: Equatable {
    let title: String
    let text: String
    let sections: [DocumentSection]
    let checksum: String
    let modifiedAt: Date?
    let keywords: [String]
}

struct MarkdownProcessor {
    func extract(from url: URL, documentID: UUID) throws -> MarkdownExtractionResult {
        let data = try Data(contentsOf: url)
        let raw = String(decoding: data, as: UTF8.self)
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let modifiedAt = attrs?[.modificationDate] as? Date
        let checksum = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()

        let parsed = splitFrontmatter(from: raw)
        let bodyLines = parsed.body.components(separatedBy: .newlines)
        let sections = buildSections(lines: bodyLines, lineOffset: parsed.bodyStartLine - 1, documentID: documentID)
        let title = inferTitle(frontmatter: parsed.frontmatter, bodyLines: bodyLines, fallback: url.deletingPathExtension().lastPathComponent)
        let text = sections.map(\.text).joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let keywords = inferKeywords(from: title + "\n" + text)

        return MarkdownExtractionResult(
            title: title,
            text: text,
            sections: sections,
            checksum: checksum,
            modifiedAt: modifiedAt,
            keywords: keywords
        )
    }

    private func splitFrontmatter(from raw: String) -> (frontmatter: [String: String], body: String, bodyStartLine: Int) {
        guard raw.hasPrefix("---\n") || raw.hasPrefix("---\r\n") else {
            return ([:], raw, 1)
        }

        let lines = raw.components(separatedBy: .newlines)
        guard lines.first == "---" else {
            return ([:], raw, 1)
        }

        var frontmatter: [String: String] = [:]
        var index = 1
        while index < lines.count {
            let line = lines[index]
            if line == "---" {
                let body = lines[(index + 1)...].joined(separator: "\n")
                return (frontmatter, body, index + 2)
            }
            if let separator = line.firstIndex(of: ":") {
                let key = line[..<separator].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty, !value.isEmpty {
                    frontmatter[String(key)] = String(value)
                }
            }
            index += 1
        }

        return ([:], raw, 1)
    }

    private func inferTitle(frontmatter: [String: String], bodyLines: [String], fallback: String) -> String {
        if let title = frontmatter["title"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            return title
        }
        for line in bodyLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("#") {
                let heading = trimmed.drop(while: { $0 == "#" || $0.isWhitespace })
                if !heading.isEmpty {
                    return String(heading)
                }
            }
        }
        return fallback
    }

    private func buildSections(lines: [String], lineOffset: Int, documentID: UUID) -> [DocumentSection] {
        guard !lines.isEmpty else { return [] }

        struct HeadingState {
            var level: Int
            var text: String
        }

        var stack: [HeadingState] = []
        var sections: [DocumentSection] = []
        var currentStart = 1
        var currentLines: [String] = []
        var currentTitle: String?
        var order = 0

        func flush(endLine: Int) {
            let text = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                currentLines.removeAll(keepingCapacity: true)
                return
            }
            let anchor = CitationAnchor(
                documentID: documentID,
                sourceKind: .markdown,
                pageStart: nil,
                pageEnd: nil,
                headingPath: stack.map(\.text),
                lineStart: currentStart,
                lineEnd: max(currentStart, endLine),
                charStart: nil,
                charEnd: nil
            )
            sections.append(
                DocumentSection(
                    id: UUID(),
                    order: order,
                    title: currentTitle,
                    text: text,
                    anchor: anchor
                )
            )
            order += 1
            currentLines.removeAll(keepingCapacity: true)
        }

        for (idx, rawLine) in lines.enumerated() {
            let lineNumber = idx + 1 + lineOffset
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if let heading = parseHeading(from: trimmed) {
                flush(endLine: lineNumber - 1)
                while let last = stack.last, last.level >= heading.level {
                    stack.removeLast()
                }
                stack.append(.init(level: heading.level, text: heading.text))
                currentTitle = heading.text
                currentStart = lineNumber
                currentLines = [rawLine]
                continue
            }

            if currentLines.isEmpty {
                currentStart = lineNumber
            }
            currentLines.append(rawLine)
        }

        flush(endLine: lines.count)
        return sections
    }

    private func parseHeading(from line: String) -> (level: Int, text: String)? {
        guard line.hasPrefix("#") else { return nil }
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard hashes > 0, hashes <= 6 else { return nil }
        let text = line.dropFirst(hashes).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return (hashes, text)
    }

    private func inferKeywords(from text: String, limit: Int = 12) -> [String] {
        let tokens = text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        var counts: [String: Int] = [:]
        for token in tokens where token.count > 3 {
            counts[String(token), default: 0] += 1
        }
        return counts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
    }
}
