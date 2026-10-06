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

        // Cents-first entry: typing 1-2-5-0 reads as 12.50 (exact value covered
        // by CentsAmount unit tests; here we just need a valid amount).
        let amount = app.textFields["0.00"]
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        amount.tap()
        amount.typeText("1250")

        // Merchant is required (#6).
        let merchant = app.textFields["e.g. Village Grocer"]
        merchant.tap()
        merchant.typeText("Kopitiam")

        let source = app.textFields["e.g. Maybank debit, Cash"]
        source.tap()
        source.typeText("Cash")

        app.navigationBars.buttons["Add"].tap()

        // The new row shows the merchant; this confirms the add flow end-to-end.
        XCTAssertTrue(app.staticTexts["Kopitiam"].waitForExistence(timeout: 3))
    }
}
