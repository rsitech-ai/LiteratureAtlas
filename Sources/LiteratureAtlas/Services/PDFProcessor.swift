import Foundation
import CryptoKit
import PDFKit

struct PDFExtractionResult: Equatable {
    let title: String
    let text: String
    let sections: [DocumentSection]
    let pageCount: Int?
    let year: Int?
    let checksum: String
    let modifiedAt: Date?
    let keywords: [String]
}

struct PDFProcessor {
    private static func plausibleYear(_ year: Int) -> Int? {
        let current = Calendar.current.component(.year, from: Date())
        // Allow a small future buffer for preprints; reject obviously-wrong matches like "2039" from arXiv IDs.
        guard year >= 1900, year <= current + 1 else { return nil }
        return year
    }

    private static func inferArxivYear(fromFileName name: String) -> Int? {
        // arXiv "new" IDs are of the form YYMM.NNNNN (optionally followed by version like v1).
        // Example filename token: 2512.12039v1_...
        let pattern = #"(?<!\d)\d{4}\.\d{4,5}(?!\d)"#
        guard let range = name.range(of: pattern, options: .regularExpression) else { return nil }

        let id = name[range]
        guard let dot = id.firstIndex(of: ".") else { return nil }
        let left = id[..<dot] // YYMM
        guard left.count == 4, left.allSatisfy(\.isNumber) else { return nil }

        let yy = Int(left.prefix(2)) ?? 0
        let mm = Int(left.suffix(2)) ?? 0
        guard (1...12).contains(mm) else { return nil }

        let currentYear = Calendar.current.component(.year, from: Date())
        let currentYY = currentYear % 100
        let year = (yy <= currentYY + 1) ? (2000 + yy) : (1900 + yy)
        return plausibleYear(year)
    }

    func extractFirstPagesText(from url: URL, maxPages: Int) throws -> String {
        guard let doc = PDFDocument(url: url) else {
            throw PDFError.failedToOpen
        }
        let pageCount = doc.pageCount
        let pagesToRead = min(maxPages, pageCount)
        guard pagesToRead > 0 else { throw PDFError.noPages }

        var text = ""
        for index in 0..<pagesToRead {
            if let page = doc.page(at: index), let pageText = page.string {
                text.append(pageText)
                text.append("\n\n")
            }
        }
        return text
    }

    func pageCount(for url: URL) -> Int? {
        guard let doc = PDFDocument(url: url) else { return nil }
        let count = doc.pageCount
        return count > 0 ? count : nil
    }

    func inferTitle(for url: URL, text: String) -> String {
        if let doc = PDFDocument(url: url),
           let attrs = doc.documentAttributes,
           let metaTitle = attrs[PDFDocumentAttribute.titleAttribute] as? String,
           !metaTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return metaTitle
        }
        if let firstLine = text.split(separator: "\n").first {
            let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return String(trimmed.prefix(120))
            }
        }
        return url.deletingPathExtension().lastPathComponent
    }

    func inferYear(from url: URL) -> Int? {
        if let doc = PDFDocument(url: url),
           let attrs = doc.documentAttributes {
            if let created = attrs[PDFDocumentAttribute.creationDateAttribute] as? Date {
                if let year = Calendar.current.dateComponents([.year], from: created).year,
                   let plausible = Self.plausibleYear(year) {
                    return plausible
                }
            }
            if let modified = attrs[PDFDocumentAttribute.modificationDateAttribute] as? Date {
                if let year = Calendar.current.dateComponents([.year], from: modified).year,
                   let plausible = Self.plausibleYear(year) {
                    return plausible
                }
            }
        }
        // Fallback: parse a standalone 4-digit year in the filename (avoid matching inside longer digit runs).
        let name = url.deletingPathExtension().lastPathComponent
        let pattern = #"(?<!\d)(?:20\d{2}|19\d{2})(?!\d)"#
        if let range = name.range(of: pattern, options: .regularExpression),
           let parsed = Int(name[range]),
           let plausible = Self.plausibleYear(parsed) {
            return plausible
        }
        if let arxivYear = Self.inferArxivYear(fromFileName: name) {
            return arxivYear
        }
        return nil
    }

    func inferYear(fromText text: String) -> Int? {
        let pattern = #"(?<!\d)(?:20\d{2}|19\d{2})(?!\d)"#
        if let range = text.range(of: pattern, options: .regularExpression),
           let parsed = Int(text[range]),
           let plausible = Self.plausibleYear(parsed) {
            return plausible
        }
        return nil
    }

    func extractDocument(from url: URL, documentID: UUID, maxPages: Int? = nil) throws -> PDFExtractionResult {
        let data = try Data(contentsOf: url)
        let checksum = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let modifiedAt = attrs?[.modificationDate] as? Date

        guard let doc = PDFDocument(url: url) else {
            throw PDFError.failedToOpen
        }

        let totalPages = doc.pageCount
        guard totalPages > 0 else {
            throw PDFError.noPages
        }

        let pagesToRead = min(maxPages ?? totalPages, totalPages)
        var sections: [DocumentSection] = []
        var combined: [String] = []
        for index in 0..<pagesToRead {
            guard let page = doc.page(at: index),
                  let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !pageText.isEmpty else {
                continue
            }
            let pageNumber = index + 1
            let anchor = CitationAnchor(
                documentID: documentID,
                sourceKind: .pdf,
                pageStart: pageNumber,
                pageEnd: pageNumber,
                headingPath: nil,
                lineStart: nil,
                lineEnd: nil,
                charStart: nil,
                charEnd: nil
            )
            sections.append(
                DocumentSection(
                    id: UUID(),
                    order: index,
                    title: "Page \(pageNumber)",
                    text: pageText,
                    anchor: anchor
                )
            )
            combined.append(pageText)
        }

        let combinedText = combined.joined(separator: "\n\n")
        let title = inferTitle(for: url, text: combinedText)
        let year = inferYear(from: url) ?? inferYear(fromText: combinedText)
        return PDFExtractionResult(
            title: title,
            text: combinedText,
            sections: sections,
            pageCount: totalPages,
            year: year,
            checksum: checksum,
            modifiedAt: modifiedAt,
            keywords: inferKeywords(from: title + "\n" + combinedText)
        )
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

    enum PDFError: LocalizedError {
        case failedToOpen
        case noPages

        var errorDescription: String? {
            switch self {
            case .failedToOpen: return "Failed to open PDF."
            case .noPages: return "PDF has no pages."
            }
        }
    }
}
