import SwiftUI

@available(macOS 26, iOS 26, *)
struct RootView: View {
    @EnvironmentObject private var nav: AppNavigation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GalaxyBackdrop(intensity: 1.0)

            TabView(selection: $nav.selectedTab) {
                IngestView()
                    .tabItem { Label("Ingest", systemImage: "tray.and.arrow.down") }
                    .tag(AppNavigation.Tab.ingest)

                MapView()
                    .tabItem { Label("Map", systemImage: "circle.grid.3x3") }
                    .tag(AppNavigation.Tab.map)

                QuestionView()
                    .tabItem { Label("Q&A", systemImage: "questionmark.circle") }
                    .tag(AppNavigation.Tab.qa)

                TradingLensView()
                    .tabItem { Label("Trading", systemImage: "dollarsign.circle") }
                    .tag(AppNavigation.Tab.trading)

                StrategyProjectsView()
                    .tabItem { Label("Projects", systemImage: "point.3.connected.trianglepath") }
                    .tag(AppNavigation.Tab.projects)

                AnalyticsView()
                    .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
                    .tag(AppNavigation.Tab.analytics)
            }
            .tint(GalaxyTheme.nebulaBlue)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.995)))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: nav.selectedTab)

            GlobalProgressOverlay()
        }
    }
}
