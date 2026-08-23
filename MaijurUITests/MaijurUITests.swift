//
//  MaijurUITests.swift
//  MaijurUITests
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import XCTest

final class MaijurUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppShellShowsTwoTabsAndPopulatedJournals() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["journals-tab"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["history-tab"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["journals-root-populated"].exists)
        XCTAssertTrue(app.buttons["new-journal-button"].exists)
    }
}
