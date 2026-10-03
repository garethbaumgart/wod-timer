import XCTest
@testable import WODTimerWatch

final class TimerDurationTests: XCTestCase {

    func testZero() {
        XCTAssertEqual(TimerDuration.zero.seconds, 0)
        XCTAssertEqual(TimerDuration.zero.formatted, "00:00")
    }

    func testFromSeconds() {
        let d = TimerDuration(seconds: 125)
        XCTAssertEqual(d.minutes, 2)
        XCTAssertEqual(d.remainingSeconds, 5)
        XCTAssertEqual(d.formatted, "02:05")
    }

    func testFromMinutesAndSeconds() {
        let d = TimerDuration.fromMinutesAndSeconds(10, 30)
        XCTAssertEqual(d.seconds, 630)
    }

    func testClampsToMax() {
        let d = TimerDuration(seconds: 8000)
        XCTAssertEqual(d.seconds, TimerDuration.maxSeconds)
    }

    func testClampsToZero() {
        let d = TimerDuration(seconds: -5)
        XCTAssertEqual(d.seconds, 0)
    }

    func testAddition() {
        let a = TimerDuration(seconds: 60)
        let b = TimerDuration(seconds: 30)
        XCTAssertEqual((a + b).seconds, 90)
    }

    func testSubtraction() {
        let a = TimerDuration(seconds: 60)
        let b = TimerDuration(seconds: 90)
        XCTAssertEqual((a - b).seconds, 0) // Clamped to zero
    }

    func testComparable() {
        let a = TimerDuration(seconds: 60)
        let b = TimerDuration(seconds: 120)
        XCTAssertTrue(a < b)
        XCTAssertFalse(a > b)
        XCTAssertTrue(a <= b)
    }

    func testEquality() {
        let a = TimerDuration(seconds: 300)
        let b = TimerDuration(seconds: 300)
        XCTAssertEqual(a, b)
    }

    func testFormatted() {
        XCTAssertEqual(TimerDuration(seconds: 0).formatted, "00:00")
        XCTAssertEqual(TimerDuration(seconds: 9).formatted, "00:09")
        XCTAssertEqual(TimerDuration(seconds: 65).formatted, "01:05")
        XCTAssertEqual(TimerDuration(seconds: 600).formatted, "10:00")
        XCTAssertEqual(TimerDuration(seconds: 3661).formatted, "61:01")
    }
}

/// 1.3.0 / 2.0.0 display forms: the clock never zero-pads minutes, a phase
/// reads "20s" under a minute and "2:00" from a minute up.
final class TimerDurationDisplayTests: XCTestCase {
    func testClockNeverZeroPadsMinutes() {
        XCTAssertEqual(TimerDuration(seconds: 585).clock, "9:45")
        XCTAssertEqual(TimerDuration(seconds: 11).clock, "0:11")
        XCTAssertEqual(TimerDuration(seconds: 750).clock, "12:30")
        XCTAssertEqual(TimerDuration.zero.clock, "0:00")
        XCTAssertEqual(TimerDuration(seconds: 3600).clock, "60:00")
    }

    func testPhaseReadsSecondsUnderAMinuteAndClockFromOne() {
        XCTAssertEqual(TimerDuration(seconds: 20).phase, "20s")
        XCTAssertEqual(TimerDuration(seconds: 59).phase, "59s")
        XCTAssertEqual(TimerDuration(seconds: 60).phase, "1:00")
        XCTAssertEqual(TimerDuration(seconds: 65).phase, "1:05")
        XCTAssertEqual(TimerDuration(seconds: 120).phase, "2:00")
    }

    func testTimeIntervalAndMinutes() {
        let d = TimerDuration(seconds: 125)
        XCTAssertEqual(d.timeInterval, 125)
        XCTAssertEqual(d.minutes, 2)
        XCTAssertEqual(d.remainingSeconds, 5)
    }
}
