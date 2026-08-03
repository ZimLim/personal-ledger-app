import XCTest

/// Smoke test that the app launches and renders the scaffold landing view.
/// TODO(Phase 1): expand into the critical-flow journeys (add/edit/delete/export).
final class PersonalLedgerUITests: XCTestCase {

    func testAppLaunchesToLedger() throws {
        let app = XCUIApplication()
        app.launch()
        // The ledger's pinned Add button is always present on the landing screen.
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 5))
    }

    /// End-to-end: adding a transaction through the sheet makes it appear in the
    /// current month's ledger (RFC §FR-1/§FR-2 wiring).
    func testAddTransactionAppearsInLedger() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Add Transaction"].tap()

        let amount = app.textFields["0.00"]
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        amount.tap()
        amount.typeText("12.50")

        let source = app.textFields["e.g. Maybank debit, Cash"]
        source.tap()
        source.typeText("Cash")

        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["RM 12.50"].waitForExistence(timeout: 3))
    }
}
