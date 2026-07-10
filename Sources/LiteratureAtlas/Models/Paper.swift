import Foundation

struct Paper: Identifiable, Codable, Equatable {
    // Order here drives JSON field order (encoder keeps declaration order).
    var version: Int
    var sourceKind: SourceKind
    var filePath: String
    var sourceChecksum: String?
    var sourceModifiedAt: Date?
    var extractStatus: DocumentExtractStatus?
    var id: UUID
    var originalFilename: String
    var title: String
    var introSummary: String?
    var summary: String
    var methodSummary: String?
    var resultsSummary: String?
    var takeaways: [String]?
    var keywords: [String]?
    var tradingLens: PaperTradingLens?
    var tradingScores: TradingLensScores?
    var strategyBlueprint: String?
    var backtestAudit: String?
    var userNotes: String?
    var userTags: [String]?
    var isImportant: Bool?
    var readingStatus: ReadingStatus?
    var noteEmbedding: [Float]?
    var userQuestions: [String]?
    var flashcards: [Flashcard]?
    var firstReadAt: Date?
    var ingestedAt: Date?
    var pageCount: Int?
    var year: Int?
    var embedding: [Float]
    var clusterIndex: Int?
    var citationAnchors: [CitationAnchor]?
    var sections: [DocumentSection]?
    var compiledArtifacts: [CompiledArtifactRef]?
    // Claim-level reasoning fields
    var claims: [PaperClaim]?
    var assumptions: [String]?
    var evaluationContext: EvaluationContext?
    var methodPipeline: MethodPipeline?

    // Back-compat for old JSONs that had `fingerprint` or `status`.
    private var fingerprint: String? = nil
    private var status: String? = nil

    var fileURL: URL { URL(fileURLWithPath: filePath) }

    enum CodingKeys: String, CodingKey {
        case version, sourceKind, filePath, sourceChecksum, sourceModifiedAt, extractStatus, id, originalFilename, title, introSummary, summary, methodSummary, resultsSummary, takeaways, keywords
        case tradingLens = "trading_lens"
        case tradingScores = "scores"
        case strategyBlueprint = "strategy_blueprint"
        case backtestAudit = "backtest_audit"
        case userNotes, userTags, isImportant, readingStatus, noteEmbedding, userQuestions, flashcards, firstReadAt, ingestedAt, pageCount, year, embedding, clusterIndex, fingerprint, status
        case citationAnchors, sections, compiledArtifacts
        case claims, assumptions, evaluationContext, methodPipeline
    }

    init(version: Int = 1,
         sourceKind: SourceKind = .pdf,
         filePath: String,
         sourceChecksum: String? = nil,
         sourceModifiedAt: Date? = nil,
         extractStatus: DocumentExtractStatus? = nil,
         id: UUID,
         originalFilename: String,
         title: String,
         introSummary: String?,
         summary: String,
        methodSummary: String?,
        resultsSummary: String?,
        takeaways: [String]?,
        keywords: [String]?,
         tradingLens: PaperTradingLens? = nil,
         tradingScores: TradingLensScores? = nil,
         strategyBlueprint: String? = nil,
         backtestAudit: String? = nil,
        userNotes: String?,
        userTags: [String]?,
         isImportant: Bool? = nil,
        readingStatus: ReadingStatus?,
        noteEmbedding: [Float]?,
        userQuestions: [String]?,
         flashcards: [Flashcard]?,
         year: Int?,
         embedding: [Float],
         clusterIndex: Int?,
         citationAnchors: [CitationAnchor]? = nil,
         sections: [DocumentSection]? = nil,
         compiledArtifacts: [CompiledArtifactRef]? = nil,
         claims: [PaperClaim]? = nil,
         assumptions: [String]? = nil,
         evaluationContext: EvaluationContext? = nil,
         methodPipeline: MethodPipeline? = nil,
         firstReadAt: Date? = nil,
         ingestedAt: Date? = nil,
         pageCount: Int? = nil) {
        self.version = version
        self.sourceKind = sourceKind
        self.filePath = filePath
        self.sourceChecksum = sourceChecksum
        self.sourceModifiedAt = sourceModifiedAt
        self.extractStatus = extractStatus
        self.id = id
        self.originalFilename = originalFilename
        self.title = title
        self.introSummary = introSummary
        self.summary = summary
        self.methodSummary = methodSummary
        self.resultsSummary = resultsSummary
        self.takeaways = takeaways
        self.keywords = keywords
        self.tradingLens = tradingLens
        self.tradingScores = tradingScores ?? tradingLens?.scores
        self.strategyBlueprint = strategyBlueprint
        self.backtestAudit = backtestAudit
        self.userNotes = userNotes
        self.userTags = userTags
        self.isImportant = isImportant
        self.readingStatus = readingStatus
        self.noteEmbedding = noteEmbedding
        self.userQuestions = userQuestions
        self.flashcards = flashcards
        self.firstReadAt = firstReadAt
        self.ingestedAt = ingestedAt
        self.pageCount = pageCount
        self.year = year
        self.embedding = embedding
        self.clusterIndex = clusterIndex
        self.citationAnchors = citationAnchors
        self.sections = sections
        self.compiledArtifacts = compiledArtifacts
        self.claims = claims
        self.assumptions = assumptions
        self.evaluationContext = evaluationContext
        self.methodPipeline = methodPipeline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        sourceKind = try container.decodeIfPresent(SourceKind.self, forKey: .sourceKind) ?? .pdf
        filePath = try container.decode(String.self, forKey: .filePath)
        sourceChecksum = try container.decodeIfPresent(String.self, forKey: .sourceChecksum)
        sourceModifiedAt = try container.decodeIfPresent(Date.self, forKey: .sourceModifiedAt)
        extractStatus = try container.decodeIfPresent(DocumentExtractStatus.self, forKey: .extractStatus)
        id = try container.decode(UUID.self, forKey: .id)
        originalFilename = try container.decode(String.self, forKey: .originalFilename)
        title = try container.decode(String.self, forKey: .title)
        introSummary = try container.decodeIfPresent(String.self, forKey: .introSummary)
        summary = try container.decode(String.self, forKey: .summary)
        methodSummary = try container.decodeIfPresent(String.self, forKey: .methodSummary)
        resultsSummary = try container.decodeIfPresent(String.self, forKey: .resultsSummary)
        takeaways = try container.decodeIfPresent([String].self, forKey: .takeaways)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        tradingLens = try container.decodeIfPresent(PaperTradingLens.self, forKey: .tradingLens)
        tradingScores = try container.decodeIfPresent(TradingLensScores.self, forKey: .tradingScores) ?? tradingLens?.scores
        strategyBlueprint = try container.decodeIfPresent(String.self, forKey: .strategyBlueprint)
        backtestAudit = try container.decodeIfPresent(String.self, forKey: .backtestAudit)
        userNotes = try container.decodeIfPresent(String.self, forKey: .userNotes)
        userTags = try container.decodeIfPresent([String].self, forKey: .userTags)
        isImportant = try container.decodeIfPresent(Bool.self, forKey: .isImportant)
        readingStatus = try container.decodeIfPresent(ReadingStatus.self, forKey: .readingStatus)
        // Legacy `status` field
        status = try container.decodeIfPresent(String.self, forKey: .status)
        if readingStatus == nil, let legacy = status {
            readingStatus = ReadingStatus(rawValue: legacy)
        }
        noteEmbedding = try container.decodeIfPresent([Float].self, forKey: .noteEmbedding)
        userQuestions = try container.decodeIfPresent([String].self, forKey: .userQuestions)
        flashcards = try container.decodeIfPresent([Flashcard].self, forKey: .flashcards)
        firstReadAt = try container.decodeIfPresent(Date.self, forKey: .firstReadAt)
        ingestedAt = try container.decodeIfPresent(Date.self, forKey: .ingestedAt)
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        embedding = try container.decode([Float].self, forKey: .embedding)
        clusterIndex = try container.decodeIfPresent(Int.self, forKey: .clusterIndex)
        citationAnchors = try container.decodeIfPresent([CitationAnchor].self, forKey: .citationAnchors)
        sections = try container.decodeIfPresent([DocumentSection].self, forKey: .sections)
        compiledArtifacts = try container.decodeIfPresent([CompiledArtifactRef].self, forKey: .compiledArtifacts)
        claims = try container.decodeIfPresent([PaperClaim].self, forKey: .claims)
        assumptions = try container.decodeIfPresent([String].self, forKey: .assumptions)
        evaluationContext = try container.decodeIfPresent(EvaluationContext.self, forKey: .evaluationContext)
        methodPipeline = try container.decodeIfPresent(MethodPipeline.self, forKey: .methodPipeline)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(sourceKind, forKey: .sourceKind)
        try container.encode(filePath, forKey: .filePath)
        try container.encodeIfPresent(sourceChecksum, forKey: .sourceChecksum)
        try container.encodeIfPresent(sourceModifiedAt, forKey: .sourceModifiedAt)
        try container.encodeIfPresent(extractStatus, forKey: .extractStatus)
        try container.encode(id, forKey: .id)
        try container.encode(originalFilename, forKey: .originalFilename)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(introSummary, forKey: .introSummary)
        try container.encode(summary, forKey: .summary)
        try container.encodeIfPresent(methodSummary, forKey: .methodSummary)
        try container.encodeIfPresent(resultsSummary, forKey: .resultsSummary)
        try container.encodeIfPresent(takeaways, forKey: .takeaways)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encodeIfPresent(tradingLens, forKey: .tradingLens)
        try container.encodeIfPresent(tradingScores ?? tradingLens?.scores, forKey: .tradingScores)
        try container.encodeIfPresent(strategyBlueprint, forKey: .strategyBlueprint)
        try container.encodeIfPresent(backtestAudit, forKey: .backtestAudit)
        try container.encodeIfPresent(userNotes, forKey: .userNotes)
        try container.encodeIfPresent(userTags, forKey: .userTags)
        try container.encodeIfPresent(isImportant, forKey: .isImportant)
        try container.encodeIfPresent(readingStatus, forKey: .readingStatus)
        try container.encodeIfPresent(noteEmbedding, forKey: .noteEmbedding)
        try container.encodeIfPresent(userQuestions, forKey: .userQuestions)
        try container.encodeIfPresent(flashcards, forKey: .flashcards)
        try container.encodeIfPresent(firstReadAt, forKey: .firstReadAt)
        try container.encodeIfPresent(ingestedAt, forKey: .ingestedAt)
        try container.encodeIfPresent(pageCount, forKey: .pageCount)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encode(embedding, forKey: .embedding)
        try container.encodeIfPresent(clusterIndex, forKey: .clusterIndex)
        try container.encodeIfPresent(citationAnchors, forKey: .citationAnchors)
        try container.encodeIfPresent(sections, forKey: .sections)
        try container.encodeIfPresent(compiledArtifacts, forKey: .compiledArtifacts)
        try container.encodeIfPresent(claims, forKey: .claims)
        try container.encodeIfPresent(assumptions, forKey: .assumptions)
        try container.encodeIfPresent(evaluationContext, forKey: .evaluationContext)
        try container.encodeIfPresent(methodPipeline, forKey: .methodPipeline)
        // Keep legacy field for older readers
        if let status = readingStatus?.rawValue {
            try container.encode(status, forKey: .status)
        }
    }
}

enum ReadingStatus: String, Codable, CaseIterable {
    case unread
    case inProgress
    case done

    var label: String {
        switch self {
        case .unread: return "Unread"
        case .inProgress: return "In progress"
        case .done: return "Done"
        }
    }
}

struct Flashcard: Identifiable, Codable, Equatable {
    var id: UUID
    var question: String
    var answer: String
    var lastReviewedAt: Date?
    var reviewCount: Int?
}
