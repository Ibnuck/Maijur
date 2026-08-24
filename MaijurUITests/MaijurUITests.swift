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

        XCTAssertTrue(app.navigationBars["Jurnal"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.buttons["new-journal-button"].exists)

        app.buttons["new-journal-button"].tap()
        let editor = app.textViews["journal-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("A quiet walk gave me space to think.")
        app.buttons["save-journal-button"].tap()

        XCTAssertTrue(app.staticTexts["A quiet walk gave me space to think."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["journals-root-populated"].exists)

        app.staticTexts["A quiet walk gave me space to think."].tap()
        XCTAssertTrue(app.buttons["open-insights-button"].waitForExistence(timeout: 3))
        app.buttons["open-insights-button"].tap()
        XCTAssertTrue(app.buttons["create-insights-button"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["journal-detail-text"].exists)
    }

    @MainActor
    func testUnchangedEditKeepsSaveDisabled() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.buttons["new-journal-button"].tap()
        let editor = app.textViews["journal-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.tap()
        editor.typeText("A detail I may want to revisit.")
        app.buttons["save-journal-button"].tap()

        app.staticTexts["A detail I may want to revisit."].tap()
        app.buttons["edit-journal-button"].tap()

        let saveButton = app.buttons["save-journal-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertFalse(saveButton.isEnabled)

        let editedText = app.textViews["journal-text-editor"]
        editedText.tap()
        editedText.typeText(" More context.")
        XCTAssertTrue(saveButton.isEnabled)
    }
}
