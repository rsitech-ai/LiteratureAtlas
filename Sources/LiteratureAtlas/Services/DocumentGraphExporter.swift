import Foundation

enum DocumentGraphExporter {
    struct Snapshot: Codable {
        let generatedAt: Date
        let nodes: [Node]
        let edges: [Edge]
    }

    struct Node: Codable {
        let id: String
        let kind: String
        let title: String
        let path: String?
        let sourceKind: String?
    }

    struct Edge: Codable {
        let source: String
        let target: String
        let relation: String
        let evidence: [String]
    }

    static func write(
        papers: [Paper],
        clusters: [Cluster],
        claimEdges: [ClaimEdge],
        outputRoot: URL
    ) {
        let folder = outputRoot.appendingPathComponent("graph", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let snapshot = buildSnapshot(papers: papers, clusters: clusters, claimEdges: claimEdges)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let url = folder.appendingPathComponent("corpus_graph.json")
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func buildSnapshot(
        papers: [Paper],
        clusters: [Cluster],
        claimEdges: [ClaimEdge]
    ) -> Snapshot {
        let entityGroups = Dictionary(grouping: papers.flatMap { paper in
            (paper.keywords ?? []).prefix(16).map { (normalizeEntity($0), paper.id) }
        }, by: \.0)
        .filter { key, value in
            !key.isEmpty && Set(value.map(\.1)).count >= 2
        }

        var nodes: [Node] = []
        var edges: [Edge] = []

        for paper in papers {
            nodes.append(
                Node(
                    id: documentNodeID(for: paper.id),
                    kind: "document",
                    title: paper.title.isEmpty ? paper.originalFilename : paper.title,
                    path: paper.filePath,
                    sourceKind: paper.sourceKind.rawValue
                )
            )

            for artifact in paper.compiledArtifacts ?? [] {
                nodes.append(
                    Node(
                        id: compiledArtifactNodeID(kind: artifact.kind, path: artifact.path),
                        kind: "compiled_note",
                        title: URL(fileURLWithPath: artifact.path).deletingPathExtension().lastPathComponent,
                        path: artifact.path,
                        sourceKind: nil
                    )
                )
                edges.append(
                    Edge(
                        source: documentNodeID(for: paper.id),
                        target: compiledArtifactNodeID(kind: artifact.kind, path: artifact.path),
                        relation: artifact.kind.rawValue,
                        evidence: artifact.citations?.map(\.displayLabel) ?? []
                    )
                )
            }

            if let clusterID = paper.clusterIndex {
                edges.append(
                    Edge(
                        source: documentNodeID(for: paper.id),
                        target: topicNodeID(for: clusterID),
                        relation: "belongs_to",
                        evidence: paper.citationAnchors?.prefix(1).map(\.displayLabel) ?? []
                    )
                )
            }

            let entityNames = Set((paper.keywords ?? []).map(normalizeEntity).filter { entityGroups[$0] != nil })
            for entity in entityNames {
                edges.append(
                    Edge(
                        source: documentNodeID(for: paper.id),
                        target: entityNodeID(for: entity),
                        relation: "mentions",
                        evidence: paper.citationAnchors?.prefix(2).map(\.displayLabel) ?? []
                    )
                )
            }
        }

        for cluster in clusters {
            nodes.append(
                Node(
                    id: topicNodeID(for: cluster.id),
                    kind: "topic",
                    title: cluster.name.isEmpty ? "Cluster \(cluster.id)" : cluster.name,
                    path: nil,
                    sourceKind: nil
                )
            )
        }

        for entity in entityGroups.keys.sorted() {
            let path = outputRootPathForEntity(entity)
            nodes.append(
                Node(
                    id: entityNodeID(for: entity),
                    kind: "entity",
                    title: entity,
                    path: path,
                    sourceKind: nil
                )
            )
        }

        let paperByClaimID = Dictionary(uniqueKeysWithValues: papers.flatMap { paper in
            (paper.claims ?? []).map { ($0.id, paper) }
        })

        for edge in claimEdges {
            guard let sourcePaper = paperByClaimID[edge.sourceClaimID],
                  let targetPaper = paperByClaimID[edge.targetClaimID] else {
                continue
            }
            edges.append(
                Edge(
                    source: documentNodeID(for: sourcePaper.id),
                    target: documentNodeID(for: targetPaper.id),
                    relation: edge.kind.rawValue,
                    evidence: (sourcePaper.citationAnchors?.prefix(1).map(\.displayLabel) ?? [])
                        + (targetPaper.citationAnchors?.prefix(1).map(\.displayLabel) ?? [])
                )
            )
        }

        let dedupedNodes = uniqueNodes(nodes)
        let dedupedEdges = uniqueEdges(edges)
        return Snapshot(generatedAt: Date(), nodes: dedupedNodes, edges: dedupedEdges)
    }

    private static func uniqueNodes(_ nodes: [Node]) -> [Node] {
        var seen: Set<String> = []
        var result: [Node] = []
        for node in nodes {
            if seen.insert(node.id).inserted {
                result.append(node)
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.kind == rhs.kind {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.kind < rhs.kind
        }
    }

    private static func uniqueEdges(_ edges: [Edge]) -> [Edge] {
        struct EdgeKey: Hashable {
            let source: String
            let target: String
            let relation: String
        }

        var seen: Set<EdgeKey> = []
        var result: [Edge] = []
        for edge in edges {
            let key = EdgeKey(source: edge.source, target: edge.target, relation: edge.relation)
            if seen.insert(key).inserted {
                result.append(edge)
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.source == rhs.source {
                if lhs.target == rhs.target {
                    return lhs.relation < rhs.relation
                }
                return lhs.target < rhs.target
            }
            return lhs.source < rhs.source
        }
    }

    private static func documentNodeID(for id: UUID) -> String {
        "document:\(id.uuidString)"
    }

    private static func topicNodeID(for id: Int) -> String {
        "topic:\(id)"
    }

    private static func entityNodeID(for entity: String) -> String {
        "entity:\(entity)"
    }

    private static func compiledArtifactNodeID(kind: CompiledArtifactKind, path: String) -> String {
        "compiled:\(kind.rawValue):\(path)"
    }

    private static func normalizeEntity(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func outputRootPathForEntity(_ entity: String) -> String {
        "Output/compiled/entities/\(CompiledKnowledgePaths.entityURL(for: entity, outputRoot: URL(fileURLWithPath: "/tmp")).lastPathComponent)"
    }
}
