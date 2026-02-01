import XCTest
@testable import WODTimerWatch

final class RoundCountTests: XCTestCase {

    func testDefaults() {
        XCTAssertEqual(RoundCount.one.value, 1)
        XCTAssertEqual(RoundCount.tabataDefault.value, 8)
    }

    func testClampsToMin() {
        let r = RoundCount(value: 0)
        XCTAssertEqual(r.value, 1)
    }

    func testClampsToMax() {
        let r = RoundCount(value: 200)
        XCTAssertEqual(r.value, 100)
    }

    func testIncrement() {
        let r = RoundCount(value: 5).incremented()
        XCTAssertEqual(r.value, 6)
    }

    func testIncrementAtMax() {
        let r = RoundCount(value: 100).incremented()
        XCTAssertEqual(r.value, 100)
    }

    func testDecrement() {
        let r = RoundCount(value: 5).decremented()
        XCTAssertEqual(r.value, 4)
    }

    func testDecrementAtMin() {
        let r = RoundCount(value: 1).decremented()
        XCTAssertEqual(r.value, 1)
    }

    func testEquality() {
        XCTAssertEqual(RoundCount(value: 5), RoundCount(value: 5))
        XCTAssertNotEqual(RoundCount(value: 5), RoundCount(value: 6))
    }
}
