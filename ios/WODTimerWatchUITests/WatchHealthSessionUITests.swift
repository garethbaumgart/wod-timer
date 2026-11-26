import XCTest

/// The app with its real Health session (26 Nov 2026): the permission sheet
/// as watchOS shows it, a workout session, and the heart rate the session
/// measures, which no unit test or capture scene reaches. The simulator
/// feeds a running workout session a simulated heart rate.
///
/// Every test here needs a watch that has never run the app: Health keeps
/// its answers through an uninstall, so `tool/watch/health_permission_check.sh`
/// creates a new simulator for each test and deletes it after. They are not
/// in the test gate (about a minute each, plus the simulator); run the
/// script when the Health permissions or the session change.
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

    /// What to do with a page's switch.
    private enum Answer {
        /// Leave every switch on: the careful athlete.
        case turnOn
        /// Tap the switch whatever it reads: the athlete who taps it "to
        /// enable it". On a switch that is already on, that turns it off.
        case tapEverySwitch
        /// Touch nothing and press Next or Done.
        case leave
    }

    /// Walks the Health sheet and returns each page with what its switch
    /// read before any tap ("Write Access:0"), in order; empty when no
    /// sheet came up.
    private func walkHealthSheet(_ answer: Answer) -> [String] {
        let review = system.buttons["UIA.Health.WatchAuthSheet.ReviewButton"]
        guard review.waitForExistence(timeout: 10) else { return [] }
        attach("health-sheet")
        review.tap()
        var pages: [String] = []
        for _ in 0 ..< 4 {
            let all = system.switches["UIA.Health.WatchAuthSheet.SwitchOutlet"].firstMatch
            guard all.waitForExistence(timeout: 5) else { break }
            let value = (all.value as? String) ?? "?"
            pages.append("\(system.navigationBars.firstMatch.identifier):\(value)")
            switch answer {
            case .turnOn: if value == "0" { all.tap() }
            case .tapEverySwitch: all.tap()
            case .leave: break
            }
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

    private func allowAlerts() {
        let allow = system.buttons["Allow"].firstMatch
        if allow.waitForExistence(timeout: 4) { allow.tap() }
    }

    /// The watch of an athlete on 2.6.2 or earlier: asked to save workouts
    /// and nothing else, answered with the Workouts switch on or off.
    private func answerAsBefore270(workouts: Bool) {
        app.launchArguments = ["--legacy-health-request"]
        app.launch()
        XCTAssertEqual(walkHealthSheet(workouts ? .turnOn : .leave), ["Write Access:0"],
                       "before 2.7.0 the sheet asked to save workouts and nothing else")
        allowAlerts()
        sleep(2)
        app.terminate()
        app.launchArguments = []
    }

    /// AMRAP, START, skip the get ready: the clock is running.
    private func startAnAmrap() {
        let amrap = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'AMRAP,'")).firstMatch
        XCTAssertTrue(amrap.waitForExistence(timeout: 10))
        amrap.tap()
        let start = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start'")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let skip = app.staticTexts["TAP TO SKIP"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(app.buttons["PAUSE"].waitForExistence(timeout: 5))
    }

    private func stopTheWorkout() {
        app.buttons["PAUSE"].tap()
        let stop = labelled("Stop workout")
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.press(forDuration: 1.4)
        XCTAssertTrue(app.staticTexts["Stopped"].waitForExistence(timeout: 5))
    }

    func testARealHealthSessionShowsAMeasuredHeartRate() {
        app.launch()
        XCTAssertEqual(walkHealthSheet(.turnOn), ["Write Access:0", "Read Access:0"],
                       "a new athlete is asked to save workouts, then to read the heart rate")
        allowAlerts()

        startAnAmrap()
        let heart = labelled("Heart rate ")
        XCTAssertTrue(heart.waitForExistence(timeout: 60), "the session's heart rate reaches the timer")
        print("HEART-LIVE \(heart.label)")
        attach("live-real-heart")

        stopTheWorkout()
        let summary = labelled("Heart rate: average ")
        XCTAssertTrue(summary.waitForExistence(timeout: 10), "the end screen shows the workout's average and peak")
        print("HEART-END \(summary.label)")
        attach("end-real-heart")
        app.buttons["DONE"].tap()
    }

    /// 2.7.0 asked an athlete who had already allowed workouts for both
    /// permissions. watchOS then opens on the Write Access page with the
    /// Workouts switch already ON, and a tap meant to enable it turns it
    /// off: Gareth's watch came out with the heart rate allowed and
    /// Workouts not (27 Nov 2026), so no session ran, no heart rate showed
    /// and the countdown and start beep were lost with the wrist down.
    /// The athlete here taps every switch they are shown, as he did.
    func testAnUpdatingAthleteIsAskedForTheHeartRateAloneAndKeepsTheSession() {
        answerAsBefore270(workouts: true)

        app.launch()
        XCTAssertEqual(walkHealthSheet(.tapEverySwitch), ["Read Access:0"],
                       "an athlete who allowed workouts is never shown the Workouts switch again")
        XCTAssertFalse(app.staticTexts["Workouts is off"].waitForExistence(timeout: 3))

        startAnAmrap()
        XCTAssertTrue(labelled("Heart rate ").waitForExistence(timeout: 60),
                      "the session still runs after the update, and its heart rate reaches the timer")
        attach("updated-live-heart")
        stopTheWorkout()
        app.buttons["DONE"].tap()
    }

    /// The athlete Health will not let the app save workouts for (they
    /// said no, or 2.7.0's sheet got them): Home says what that costs and
    /// where to turn it on, once, keeps a row there while it lasts, and
    /// the timer shows the bell and no heart rate.
    func testWorkoutsNotAllowedIsSaidOnHomeOnce() {
        answerAsBefore270(workouts: false)

        app.launch()
        XCTAssertEqual(walkHealthSheet(.turnOn), ["Read Access:0"])
        let title = app.staticTexts["Workouts is off"]
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Home says Workouts is off")
        XCTAssertTrue(labelled("No heart rate, and the beeps stop").exists, "and what that costs, with where to turn it on")
        attach("workouts-off-notice")
        app.buttons["OK"].tap()

        // The row under the timers, while it lasts.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["No heart rate, no beeps wrist down"].waitForExistence(timeout: 5))
        attach("workouts-off-row")
        app.swipeDown()

        startAnAmrap()
        XCTAssertTrue(labelled("No Health session").waitForExistence(timeout: 10), "the timer shows the bell, not a session")
        sleep(12)
        XCTAssertFalse(labelled("Heart rate ").exists, "no session, so no heart rate")
        attach("workouts-off-timer")
        stopTheWorkout()
        app.buttons["DONE"].tap()

        // Said once: the next launch goes straight to Home.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'AMRAP,'")).firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["OK"].waitForExistence(timeout: 4), "the notice is not put up at every launch")
    }
}
