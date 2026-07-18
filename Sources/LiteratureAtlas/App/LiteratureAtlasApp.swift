import SwiftUI
import FoundationModels

#if os(macOS)
import AppKit

@available(macOS 26, *)
@MainActor
final class LiteratureAtlasAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
#endif

@main
struct LiteratureAtlasApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var nav = AppNavigation()
    @State private var modelAvailabilityRefreshID = 0

    #if os(macOS)
    @NSApplicationDelegateAdaptor(LiteratureAtlasAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        Window("LiteratureAtlas", id: "main") {
            appContent
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandMenu("Navigate") {
                navigationCommand("Ingest", tab: .ingest, key: "1")
                navigationCommand("Universe", tab: .map, key: "2")
                navigationCommand("Q&A", tab: .qa, key: "3")
                navigationCommand("Insights", tab: .trading, key: "4")
                navigationCommand("Projects", tab: .projects, key: "5")
                navigationCommand("Analytics", tab: .analytics, key: "6")
            }
        }
        #else
        WindowGroup {
            appContent
        }
        #endif
    }

    @ViewBuilder
    private var appContent: some View {
        let _ = modelAvailabilityRefreshID
        let availability = SystemLanguageModel.default.availability
        RootView()
            .environmentObject(model)
            .environmentObject(nav)
            .safeAreaInset(edge: .top, spacing: 0) {
                if case let .unavailable(reason) = availability {
                    ModelUnavailableBanner(reason: String(describing: reason)) {
                        modelAvailabilityRefreshID &+= 1
                    }
                }
            }
    }

    #if os(macOS)
    private func navigationCommand(_ title: String, tab: AppNavigation.Tab, key: Character) -> some View {
        Button(title) {
            selectNavigationTab(tab)
        }
        .keyboardShortcut(KeyEquivalent(key), modifiers: .command)
    }

    private func selectNavigationTab(_ tab: AppNavigation.Tab) {
        nav.select(tab, collapseSidebar: false)
    }
    #endif
}

struct ModelUnavailableBanner: View {
    let reason: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Generation is unavailable; your existing library remains accessible.")
                    .font(.callout.bold())
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Button("Check again", action: retry)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial)
    }
}
