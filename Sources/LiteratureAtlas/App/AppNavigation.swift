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
            case .map: return "Map"
            case .qa: return "Q&A"
            case .trading: return "Trading"
            case .projects: return "Projects"
            case .analytics: return "Analytics"
            }
        }

        var systemImage: String {
            switch self {
            case .ingest: return "tray.and.arrow.down"
            case .map: return "circle.grid.3x3"
            case .qa: return "questionmark.circle"
            case .trading: return "dollarsign.circle"
            case .projects: return "point.3.connected.trianglepath"
            case .analytics: return "chart.xyaxis.line"
            }
        }
    }

    @Published var selectedTab: Tab = .ingest
    @Published var requestedStrategyProjectID: UUID? = nil
}
