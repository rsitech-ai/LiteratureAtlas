import Foundation

enum SourceKind: String, Codable, CaseIterable, Equatable, Sendable {
    case pdf
    case markdown

    var label: String {
        switch self {
        case .pdf: return "PDF"
        case .markdown: return "Markdown"
        }
    }
}

enum DocumentExtractStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case extracted
    case partial
    case failed
    case ocr

    var label: String {
        switch self {
        case .extracted: return "Extracted"
        case .partial: return "Partial"
        case .failed: return "Failed"
        case .ocr: return "OCR"
        }
    }
}

struct CitationAnchor: Codable, Equatable, Hashable, Sendable {
    var documentID: UUID?
    var sourceKind: SourceKind
    var pageStart: Int?
    var pageEnd: Int?
    var headingPath: [String]?
    var lineStart: Int?
    var lineEnd: Int?
    var charStart: Int?
    var charEnd: Int?

    var displayLabel: String {
        var parts: [String] = []
        switch sourceKind {
        case .pdf:
            if let pageStart {
                if let pageEnd, pageEnd != pageStart {
                    parts.append("pp. \(pageStart)-\(pageEnd)")
                } else {
                    parts.append("p. \(pageStart)")
                }
            }
        case .markdown:
            if let heading = headingPath?.last, !heading.isEmpty {
                parts.append(heading)
            }
            if let lineStart {
                if let lineEnd, lineEnd != lineStart {
                    parts.append("lines \(lineStart)-\(lineEnd)")
                } else {
                    parts.append("line \(lineStart)")
                }
            }
        }
        if parts.isEmpty {
            return sourceKind.label
        }
        return parts.joined(separator: " • ")
    }
}

struct DocumentSection: Codable, Equatable, Sendable {
    var id: UUID
    var order: Int
    var title: String?
    var text: String
    var anchor: CitationAnchor
}

enum CompiledArtifactKind: String, Codable, CaseIterable, Equatable, Sendable {
    case documentNote = "document_note"
    case topicBrief = "topic_brief"
    case entityNote = "entity_note"
    case corpusBriefing = "corpus_briefing"

    var label: String {
        switch self {
        case .documentNote: return "Document note"
        case .topicBrief: return "Topic brief"
        case .entityNote: return "Entity note"
        case .corpusBriefing: return "Corpus briefing"
        }
    }
}

struct CompiledArtifactRef: Codable, Equatable, Sendable {
    var kind: CompiledArtifactKind
    var path: String
    var generatedAt: Date?
    var citations: [CitationAnchor]?
}

typealias DocumentRecord = Paper
