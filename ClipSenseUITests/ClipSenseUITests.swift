//
//  ClipSenseUITests.swift
//  ClipSenseUITests
//
//  Created by 橋本純一 on 2026/04/26.
//

import XCTest

final class ClipSenseUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMenuBarAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertNotEqual(app.state, .notRunning)
    }
}
