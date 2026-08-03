import XCTest

/// Smoke test that the app launches and renders the scaffold landing view.
/// TODO(Phase 1): expand into the critical-flow journeys (add/edit/delete/export).
final class PersonalLedgerUITests: XCTestCase {

    func testAppLaunchesToLanding() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Personal Ledger"].waitForExistence(timeout: 5))
    }
}
