import Foundation
import OSLog

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
        #if !DISTRIBUTED_APP_BUILD
        let env = ProcessInfo.processInfo.environment
        let preferred = env["LITERATURE_ATLAS_COMPILER_PROVIDER"]?.lowercased()
        if preferred == "openai" {
            Logger(subsystem: "LiteratureAtlas", category: "Compiler")
                .warning("OpenAI API compiler requested, but standalone app OAuth/Codex auth is not supported here. Falling back to on-device compilation.")
        }
        #endif
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

#if !DISTRIBUTED_APP_BUILD
@available(macOS 26, iOS 26, *)
actor OpenAIDocumentCompilerProvider: DocumentCompilerProviding {
    private let fallback: any DocumentCompilerProviding
    private let session: URLSession
    private let apiKey: String?
    private let model: String
    private let logger = Logger(subsystem: "LiteratureAtlas", category: "OpenAICompiler")

    init(
        fallback: any DocumentCompilerProviding,
        session: URLSession = .shared,
        apiKey: String? = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
        model: String = ProcessInfo.processInfo.environment["LITERATURE_ATLAS_OPENAI_MODEL"] ?? "gpt-5.4-mini"
    ) {
        self.fallback = fallback
        self.session = session
        let cleaned = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiKey = (cleaned?.isEmpty == false) ? cleaned : nil
        self.model = model
    }

    func summarizeDocument(title: String, text: String) async throws -> DocumentCompilationResult {
        let input = """
        Title: \(title)

        Document text:
        \(LLMText.clip(text, maxChars: 18000))
        """
        let instructions = """
        You compile traceable technical document notes. Write a concise 3-6 bullet summary focused on problem, method, and results. Avoid quotes and unsupported claims.
        """
        do {
            let summary = try await respond(instructions: instructions, input: input)
            return DocumentCompilationResult(
                summary: summary,
                chunksUsed: 1,
                maxChunkCharsUsed: min(text.count, 18_000)
            )
        } catch {
            logger.warning("OpenAI summarizeDocument failed, falling back to on-device compiler: \(error.localizedDescription, privacy: .public)")
            return try await fallback.summarizeDocument(title: title, text: text)
        }
    }

    func summarizeSection(title: String, sectionName: String, text: String) async throws -> String {
        let input = """
        Title: \(title)
        Section: \(sectionName)

        Section text:
        \(LLMText.clip(text, maxChars: 8000))
        """
        let instructions = """
        Summarize the supplied document section in 2-3 concise bullet points for a technical reader. Focus on what the section does and what evidence it provides.
        """
        do {
            return try await respond(instructions: instructions, input: input)
        } catch {
            logger.warning("OpenAI summarizeSection failed, falling back to on-device compiler: \(error.localizedDescription, privacy: .public)")
            return try await fallback.summarizeSection(title: title, sectionName: sectionName, text: text)
        }
    }

    func generateTakeaways(title: String, text: String) async throws -> [String] {
        let input = """
        Title: \(title)

        Summary or text:
        \(LLMText.clip(text, maxChars: 6000))
        """
        let instructions = """
        Return 3-5 crisp bullet takeaways. Keep each bullet under 18 words and avoid placeholders like "not specified".
        """
        do {
            let response = try await respond(instructions: instructions, input: input)
            let lines = response
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { line -> String in
                    line
                        .replacingOccurrences(of: #"^\s*[-*•]\s*"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"^\s*\d+[.)]\s*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty }
            return Array(lines.prefix(5))
        } catch {
            logger.warning("OpenAI generateTakeaways failed, falling back to on-device compiler: \(error.localizedDescription, privacy: .public)")
            return try await fallback.generateTakeaways(title: title, text: text)
        }
    }

    private func respond(instructions: String, input: String) async throws -> String {
        guard let apiKey else {
            throw OpenAICompilerError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = OpenAIResponsesRequest(
            model: model,
            instructions: instructions,
            input: input,
            store: false
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAICompilerError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAICompilerError.httpFailure(statusCode: http.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponsesEnvelope.self, from: data)
        if let text = decoded.outputText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        let fallbackText = decoded.output?
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let fallbackText, !fallbackText.isEmpty else {
            throw OpenAICompilerError.emptyOutput
        }
        return fallbackText
    }
}

private struct OpenAIResponsesRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
    let store: Bool
}

private struct OpenAIResponsesEnvelope: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            let type: String?
            let text: String?
        }

        let content: [ContentItem]
    }

    let outputText: String?
    let output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private enum OpenAICompilerError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpFailure(statusCode: Int, body: String)
    case emptyOutput

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OPENAI_API_KEY is not configured."
        case .invalidResponse:
            return "OpenAI compiler returned a non-HTTP response."
        case let .httpFailure(statusCode, body):
            return "OpenAI compiler request failed with status \(statusCode): \(body)"
        case .emptyOutput:
            return "OpenAI compiler returned no text output."
        }
    }
}
#endif
