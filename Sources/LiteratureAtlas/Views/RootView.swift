import SwiftUI

@available(macOS 26, iOS 26, *)
struct RootView: View {
    @EnvironmentObject private var nav: AppNavigation

    var body: some View {
        NavigationSplitView {
            List {
                Section("Atlas") {
                    ForEach(AppNavigation.Tab.allCases) { tab in
                        Button {
                            nav.selectedTab = tab
                        } label: {
                            Label(tab.title, systemImage: tab.systemImage)
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(nav.selectedTab == tab ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(nav.selectedTab == tab ? GalaxyTheme.nebulaBlue.opacity(0.86) : Color.clear)
                        )
                        .accessibilityIdentifier("sidebar-\(tab.rawValue)")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("LiteratureAtlas")
        } detail: {
            ZStack {
                selectedView
                GlobalProgressOverlay()
            }
        }
        .tint(GalaxyTheme.nebulaBlue)
    }

    @ViewBuilder
    private var selectedView: some View {
        switch nav.selectedTab {
        case .ingest:
            IngestView()
        case .map:
            MapView()
        case .qa:
            QuestionView()
        case .trading:
            TradingLensView()
        case .projects:
            StrategyProjectsView()
        case .analytics:
            AnalyticsView()
        }
    }
}
