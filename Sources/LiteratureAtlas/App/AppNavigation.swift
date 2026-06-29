import Foundation
import SwiftUI

@available(macOS 26, iOS 26, *)
@MainActor
final class AppNavigation: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable, Hashable {
        case ingest
        case map
        case qa
        case trading
        case projects
        case analytics

        var id: String { rawValue }

        var title: String {
            switch self {
            case .ingest: return "Ingest"
            case .map: return "Universe"
            case .qa: return "Q&A"
            case .trading: return "Trading"
            case .projects: return "Projects"
            case .analytics: return "Analytics"
            }
        }

        var systemImage: String {
            switch self {
            case .ingest: return "tray.and.arrow.down"
            case .map: return "sparkles"
            case .qa: return "questionmark.circle"
            case .trading: return "dollarsign.circle"
            case .projects: return "folder"
            case .analytics: return "chart.xyaxis.line"
            }
        }
    }

    @Published var selectedTab: Tab = .map
    @Published var requestedStrategyProjectID: UUID? = nil
}
