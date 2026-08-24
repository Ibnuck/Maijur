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
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Jurnal"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["Riwayat"].exists)
        XCTAssertTrue(app.buttons["new-journal-button"].exists)

        app.buttons["new-journal-button"].tap()
        let editor = app.textViews["journal-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("A quiet walk gave me space to think.")
        app.buttons["save-journal-button"].tap()

        XCTAssertTrue(app.staticTexts["A quiet walk gave me space to think."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["journals-root-populated"].exists)
    }
}
