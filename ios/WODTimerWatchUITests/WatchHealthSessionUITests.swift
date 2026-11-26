import XCTest

/// The app with its real Health session (26 Nov 2026): the permission sheet
/// as watchOS shows it, a workout session, and the heart rate the session
/// measures, which no unit test or capture scene reaches. The simulator
/// feeds a running workout session a simulated heart rate.
///
/// For the whole flow, start from a watch that has never run the app
/// (`xcrun simctl uninstall <udid> app.mentalmetal.wharfwod.watchkitapp`):
/// the test then answers the Health sheet (workouts on the Write Access
/// page, heart rate on the Read Access page) and the notifications alert.
/// On a watch that has answered them it goes straight to the workout.
final class WatchHealthSessionUITests: XCTestCase {
    private let app = XCUIApplication()
    /// watchOS shows the system sheets from its home screen process.
    private let system = XCUIApplication(bundleIdentifier: "com.apple.Carousel")

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func labelled(_ prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Turns everything on each page of the Health sheet and presses its
    /// Next or Done. Returns the pages it answered, in order.
    private func answerHealthSheet() -> [String] {
        let review = system.buttons["UIA.Health.WatchAuthSheet.ReviewButton"]
        guard review.waitForExistence(timeout: 8) else { return [] }
        attach("health-sheet")
        review.tap()
        var pages: [String] = []
        for _ in 0 ..< 4 {
            let all = system.switches["UIA.Health.WatchAuthSheet.SwitchOutlet"].firstMatch
            guard all.waitForExistence(timeout: 5) else { break }
            pages.append(system.navigationBars.firstMatch.identifier)
            if (all.value as? String) == "0" { all.tap() }
            attach("health-\(pages.count)")
            let next = system.cells["UIA.Health.WatchAuthSheet.ConfigureCell.Button"].firstMatch
            var pressed = false
            for _ in 0 ..< 8 {
                if next.exists, next.isHittable {
                    next.tap()
                    pressed = true
                    break
                }
                system.swipeUp()
            }
            XCTAssertTrue(pressed, "the \(pages.last ?? "?") page has a Next or Done")
            sleep(2)
        }
        return pages
    }

    func testARealHealthSessionShowsAMeasuredHeartRate() {
        app.launch()
        let pages = answerHealthSheet()
        if !pages.isEmpty {
            XCTAssertEqual(pages, ["Write Access", "Read Access"],
                           "the sheet asks to save workouts, then to read the heart rate")
        }
        let allow = system.buttons["Allow"].firstMatch
        if allow.waitForExistence(timeout: 4) { allow.tap() }

        let amrap = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'AMRAP,'")).firstMatch
        XCTAssertTrue(amrap.waitForExistence(timeout: 10))
        amrap.tap()
        let start = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start'")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let skip = app.staticTexts["TAP TO SKIP"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        let pause = app.buttons["PAUSE"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        let heart = labelled("Heart rate ")
        XCTAssertTrue(heart.waitForExistence(timeout: 60), "the session's heart rate reaches the timer")
        print("HEART-LIVE \(heart.label)")
        attach("live-real-heart")

        pause.tap()
        let stop = labelled("Stop workout")
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.press(forDuration: 1.4)
        XCTAssertTrue(app.staticTexts["Stopped"].waitForExistence(timeout: 5))
        let summary = labelled("Heart rate: average ")
        XCTAssertTrue(summary.waitForExistence(timeout: 10), "the end screen shows the workout's average and peak")
        print("HEART-END \(summary.label)")
        attach("end-real-heart")
        app.buttons["DONE"].tap()
    }
}
