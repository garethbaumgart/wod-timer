import XCTest

/// Drives the watch app with real touches (26 Nov 2026). The unit tests and
/// the capture scenes cannot tap, so nothing proved that Home's tiles open
/// their setup screens, that START reaches the timer or that the heart rate
/// shows where the athlete looks. Run on any watch simulator:
///
///   xcodebuild test -project ios/Runner.xcodeproj -scheme WODTimerWatchUITests \
///     -destination "platform=watchOS Simulator,id=<udid>"
///
/// `--ui-test` runs the app without Health or notifications, so no system
/// sheet covers the screen; `--heart` gives its stand-in session a heart
/// rate (164 now, average 152, peak 178).
final class WatchFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-test", "--heart"]
        app.launch()
    }

    private func tile(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ",")).firstMatch
    }

    private func labelled(_ prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testHomeShowsAllFourTimersAndEachTileOpensItsSetup() {
        XCTAssertTrue(tile("FOR TIME").waitForExistence(timeout: 10))
        attach("home")
        for name in ["FOR TIME", "EMOM", "AMRAP", "TABATA"] {
            let button = tile(name)
            XCTAssertTrue(button.exists, "\(name) tile")
            XCTAssertTrue(button.isHittable, "\(name) is on screen without scrolling")
        }
        for name in ["FOR TIME", "EMOM", "AMRAP", "TABATA"] {
            tile(name).tap()
            let start = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start'")).firstMatch
            XCTAssertTrue(start.waitForExistence(timeout: 5), "\(name) setup has START")
            XCTAssertTrue(app.staticTexts[name].exists || app.navigationBars[name].exists || labelled(name).exists,
                          "\(name) setup shows its title")
            attach("setup-\(name)")
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(tile(name).waitForExistence(timeout: 5), "back on Home from \(name)")
        }
    }

    func testAWorkoutRunsFromATileToTheEndScreenWithItsHeartRate() {
        XCTAssertTrue(tile("EMOM").waitForExistence(timeout: 10))
        tile("EMOM").tap()
        let start = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start'")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        // Get ready: a tap on the canvas skips it.
        let skip = app.staticTexts["TAP TO SKIP"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        let pause = app.buttons["PAUSE"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        let heart = labelled("Heart rate 164 beats per minute")
        XCTAssertTrue(heart.waitForExistence(timeout: 5), "the heart rate shows on the running timer")
        attach("live")

        pause.tap()
        let resume = app.buttons["RESUME"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertFalse(labelled("Heart rate 164").exists, "no heart rate while paused")
        attach("paused")
        resume.tap()
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertTrue(heart.waitForExistence(timeout: 5), "and it is back once the clock runs")

        pause.tap()
        let stop = labelled("Stop workout")
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.press(forDuration: 1.4)

        XCTAssertTrue(app.staticTexts["Stopped"].waitForExistence(timeout: 5))
        XCTAssertTrue(labelled("Heart rate: average 152, peak 178").exists, "the end screen has the heart line")
        attach("end")

        app.buttons["DONE"].tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5), "DONE lands on the mode's setup")
    }
}
