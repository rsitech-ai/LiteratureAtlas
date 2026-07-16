import SwiftUI

@available(macOS 26, iOS 26, *)
struct RootView: View {
    @EnvironmentObject private var nav: AppNavigation
    @EnvironmentObject private var model: AppModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationSplitView(columnVisibility: $nav.splitViewVisibility) {
            List(selection: selectedTab) {
                Section("Atlas") {
                    ForEach(AppNavigation.Tab.allCases) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.title, systemImage: tab.systemImage)
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                        }
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
        .alert(
            "Source Access Needed",
            isPresented: Binding(
                get: { model.sourceAccessError != nil },
                set: { if !$0 { model.sourceAccessError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.sourceAccessError = nil }
        } message: {
            Text(model.sourceAccessError ?? "Select the source folder again to restore access.")
        }
        .alert(
            "Save Failed",
            isPresented: Binding(
                get: { model.persistenceError != nil },
                set: { if !$0 { model.persistenceError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.persistenceError = nil }
        } message: {
            Text(model.persistenceError ?? "The change could not be saved.")
        }
    }

    private var selectedTab: Binding<AppNavigation.Tab?> {
        Binding(
            get: { nav.selectedTab },
            set: { tab in
                guard let tab else { return }
                nav.select(tab, collapseSidebar: horizontalSizeClass == .compact)
            }
        )
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
