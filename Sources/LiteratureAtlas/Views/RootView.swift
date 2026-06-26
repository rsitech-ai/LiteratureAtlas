import SwiftUI

@available(macOS 26, iOS 26, *)
struct RootView: View {
    @EnvironmentObject private var nav: AppNavigation

    private var selection: Binding<AppNavigation.Tab?> {
        Binding(
            get: { nav.selectedTab },
            set: { tab in
                if let tab {
                    nav.selectedTab = tab
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                Section("Atlas") {
                    ForEach(AppNavigation.Tab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage)
                            .tag(Optional(tab))
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
