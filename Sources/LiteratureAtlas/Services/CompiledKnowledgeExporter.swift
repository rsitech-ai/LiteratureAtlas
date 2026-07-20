import Foundation

enum CompiledKnowledgeExporter {
    static func writeDocumentNotes(papers: [Paper], outputRoot: URL) throws {
        let folder = outputRoot.appendingPathComponent("compiled/documents", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for paper in papers {
            let url = CompiledKnowledgePaths.documentURL(for: paper, outputRoot: outputRoot)
            let markdown = renderDocumentNote(for: paper)
            try Data(markdown.utf8).write(to: url, options: .atomic)
        }
    }

    static func writeTopicBriefs(clusters: [Cluster], papersByID: [UUID: Paper], outputRoot: URL) throws {
        let folder = outputRoot.appendingPathComponent("compiled/topics", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for cluster in clusters {
            let url = CompiledKnowledgePaths.topicURL(for: cluster, outputRoot: outputRoot)
            let markdown = renderTopicBrief(for: cluster, papersByID: papersByID)
            try Data(markdown.utf8).write(to: url, options: .atomic)
        }
    }

    static func writeEntityNotes(papers: [Paper], outputRoot: URL) throws {
        let folder = outputRoot.appendingPathComponent("compiled/entities", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let grouped = Dictionary(grouping: papers.flatMap { paper in
            (paper.keywords ?? []).prefix(16).map { ($0.lowercased(), paper) }
        }, by: \.0)

        for (keyword, entries) in grouped where entries.count >= 2 {
            let entityName = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !entityName.isEmpty else { continue }
            let url = CompiledKnowledgePaths.entityURL(for: entityName, outputRoot: outputRoot)
            let markdown = renderEntityNote(entity: entityName, papers: entries.map(\.1))
            try Data(markdown.utf8).write(to: url, options: .atomic)
        }
    }

    private static func renderDocumentNote(for paper: Paper) -> String {
        let citations = renderCitations(paper.citationAnchors)
        let keywords = (paper.keywords ?? []).map { "`\($0)`" }.joined(separator: ", ")
        let takeaways = (paper.takeaways ?? []).prefix(5).map { "- \($0)" }.joined(separator: "\n")
        let sections = (paper.sections ?? []).prefix(10).map { section in
            var block: [String] = []
            if let title = section.title, !title.isEmpty {
                block.append("### \(title)")
            }
            block.append(LLMText.clip(section.text, maxChars: 700))
            block.append("_Citation: \(section.anchor.displayLabel)_")
            return block.joined(separator: "\n\n")
        }.joined(separator: "\n\n")

        return """
        ---
        type: compiled_document
        document_id: \(paper.id.uuidString)
        source_kind: \(paper.sourceKind.rawValue)
        source_path: \(yamlString(paper.filePath))
        ---

        # \(paper.title.isEmpty ? paper.originalFilename : paper.title)

        ## Summary
        \(paper.summary)

        ## Key Takeaways
        \(takeaways.isEmpty ? "- No takeaways available." : takeaways)

        ## Source Metadata
        - Kind: \(paper.sourceKind.label)
        - Original filename: \(paper.originalFilename)
        - Year: \(paper.year.map(String.init) ?? "Unknown")
        - Pages: \(paper.pageCount.map(String.init) ?? "Unknown")
        - Checksum: \(paper.sourceChecksum ?? "Unknown")
        - Extract status: \(paper.extractStatus?.label ?? "Unknown")
        - Keywords: \(keywords.isEmpty ? "None" : keywords)

        ## Citations
        \(citations)

        ## Evidence Sections
        \(sections.isEmpty ? "_No extracted sections available._" : sections)
        """
    }

    private static func renderTopicBrief(for cluster: Cluster, papersByID: [UUID: Paper]) -> String {
        let members = cluster.memberPaperIDs.compactMap { papersByID[$0] }
        let topTitles = members.prefix(8).map { "- \($0.title)" }.joined(separator: "\n")
        let linkedDocuments = members.prefix(8).map { paper in
            let fileName = CompiledKnowledgePaths
                .documentFileName(title: paper.title.isEmpty ? paper.originalFilename : paper.title, documentID: paper.id)
                .replacingOccurrences(of: " ", with: "%20")
            return "- [\(paper.title)](../documents/\(fileName))"
        }.joined(separator: "\n")
        return """
        ---
        type: topic_brief
        cluster_id: \(cluster.id)
        ---

        # \(cluster.name.isEmpty ? "Cluster \(cluster.id)" : cluster.name)

        ## Brief
        \(cluster.metaSummary.isEmpty ? "No topic summary available yet." : cluster.metaSummary)

        ## Member Documents
        \(topTitles.isEmpty ? "- No member documents." : topTitles)

        ## Linked Notes
        \(linkedDocuments.isEmpty ? "- No linked notes." : linkedDocuments)
        """
    }

    private static func renderEntityNote(entity: String, papers: [Paper]) -> String {
        let memberLines = papers.prefix(12).map { paper in
            let citations = renderCitations(paper.citationAnchors, prefix: "")
            return "- \(paper.title) (\(paper.sourceKind.label))\n  \(citations.replacingOccurrences(of: "\n", with: "\n  "))"
        }.joined(separator: "\n")
        return """
        ---
        type: entity_note
        entity: \(yamlString(entity))
        ---

        # \(entity.capitalized)

        ## Related Documents
        \(memberLines)
        """
    }

    private static func renderCitations(_ anchors: [CitationAnchor]?, prefix: String = "- ") -> String {
        guard let anchors, !anchors.isEmpty else {
            return "\(prefix)No citations available."
        }
        return anchors.prefix(12).map { "\(prefix)\($0.displayLabel)" }.joined(separator: "\n")
    }

    private static func yamlString(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
