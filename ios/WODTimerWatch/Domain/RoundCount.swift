import Foundation

/// A validated count of rounds/intervals for workouts (1-100).
struct RoundCount: Equatable, Codable, Hashable {
    let value: Int

    static let minRounds = 1
    static let maxRounds = 100

    static let one = RoundCount(value: 1)
    static let tabataDefault = RoundCount(value: 8)

    init(value: Int) {
        self.value = max(Self.minRounds, min(value, Self.maxRounds))
    }

    func incremented() -> RoundCount {
        RoundCount(value: value + 1)
    }

    func decremented() -> RoundCount {
        RoundCount(value: value - 1)
    }
}
