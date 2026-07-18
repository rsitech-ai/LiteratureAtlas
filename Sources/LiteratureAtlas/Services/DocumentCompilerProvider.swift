import Foundation

@available(macOS 26, iOS 26, *)
struct DocumentCompilationResult: Equatable {
    let summary: String
    let chunksUsed: Int
    let maxChunkCharsUsed: Int
}

@available(macOS 26, iOS 26, *)
protocol DocumentCompilerProviding: Sendable {
    func summarizeDocument(title: String, text: String) async throws -> DocumentCompilationResult
    func summarizeSection(title: String, sectionName: String, text: String) async throws -> String
    func generateTakeaways(title: String, text: String) async throws -> [String]
}

@available(macOS 26, iOS 26, *)
enum DocumentCompilerProviderFactory {
    static func makeDefault() -> any DocumentCompilerProviding {
        return OnDeviceDocumentCompilerProvider()
    }
}

@available(macOS 26, iOS 26, *)
actor OnDeviceDocumentCompilerProvider: DocumentCompilerProviding {
    private let summarizer = PaperSummarizerActor()

    func summarizeDocument(title: String, text: String) async throws -> DocumentCompilationResult {
        let result = try await summarizer.summarize(title: title, text: text)
        return DocumentCompilationResult(
            summary: result.summary,
            chunksUsed: result.chunksUsed,
            maxChunkCharsUsed: result.maxChunkCharsUsed
        )
    }

    func summarizeSection(title: String, sectionName: String, text: String) async throws -> String {
        try await summarizer.summarizeSection(title: title, sectionName: sectionName, text: text)
    }

    func generateTakeaways(title: String, text: String) async throws -> [String] {
        try await summarizer.generateTakeaways(title: title, text: text)
    }
}
