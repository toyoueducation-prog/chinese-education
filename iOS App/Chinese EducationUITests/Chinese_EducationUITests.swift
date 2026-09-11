//
//  Chinese_EducationUITests.swift
//  Chinese EducationUITests
//
//  Created by J Ko on 4/2/2025.
//

import XCTest

final class Chinese_EducationUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Verifies the app reaches the sign-in shell (SpriteKit login adds `UITextField`s for username/password).
    func testLaunchShowsSignInFields() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
        let usernameField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(usernameField.waitForExistence(timeout: 10), "Expected SignInScene username UITextField")
        XCTAssertTrue(app.secureTextFields.element(boundBy: 0).waitForExistence(timeout: 5), "Expected password field")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
