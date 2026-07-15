import SwiftUI
import XCTest
@testable import LiteratureAtlas

@available(macOS 26, iOS 26, *)
@MainActor
final class AppNavigationTests: XCTestCase {
    func testCompactSelectionRevealsDetailColumn() {
        let navigation = AppNavigation()

        navigation.select(.ingest, collapseSidebar: true)

        XCTAssertEqual(navigation.selectedTab, .ingest)
        XCTAssertEqual(navigation.splitViewVisibility, .detailOnly)
    }

    func testRegularSelectionPreservesSplitViewVisibility() {
        let navigation = AppNavigation()
        navigation.splitViewVisibility = .all

        navigation.select(.analytics, collapseSidebar: false)

        XCTAssertEqual(navigation.selectedTab, .analytics)
        XCTAssertEqual(navigation.splitViewVisibility, .all)
    }
}
