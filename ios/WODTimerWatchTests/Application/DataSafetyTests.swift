import XCTest
@testable import WODTimerWatch

/// Loads committed fixtures from `test/fixtures/data_safety/watch/` and
/// runs them through HEAD's JSONDecoder / UserDefaults readers.
final class DataSafetyTests: XCTestCase {

    private static let versions = [
        "1.1.0", "1.1.2", "1.1.3", "1.2.0", "1.3.0", "2.0.0", "2.1.0", "2.2.0", "2.2.1",
    ]

    private static var fixturesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("test/fixtures/data_safety/watch")
    }

    func testEveryShippedWatchFixtureDecodesThroughJSONDecoderAndRecentWorkoutsStore() throws {
        for version in Self.versions {
            let dir = Self.fixturesRoot.appendingPathComponent(version)
            let recentsURL = dir.appendingPathComponent("recent_workouts.json")
            let data = try Data(contentsOf: recentsURL)
            let decoded = try JSONDecoder().decode([Workout].self, from: data)
            XCTAssertFalse(decoded.isEmpty, "v\(version) recents")

            let expected = try JSONSerialization.jsonObject(
                with: Data(contentsOf: dir.appendingPathComponent("expected.json"))
            ) as? [String: Any]
            let want = expected?["workouts"] as? [[String: Any]] ?? []
            XCTAssertEqual(decoded.count, want.count, "v\(version) count")
            for (workout, exp) in zip(decoded, want) {
                XCTAssertEqual(workout.id.uuidString, exp["id"] as? String, "v\(version) id")
                XCTAssertEqual(workout.name, exp["name"] as? String, "v\(version) name")
                XCTAssertEqual(workout.prepCountdown.seconds, exp["prep"] as? Int, "v\(version) prep")
                XCTAssertEqual(workout.timerType.typeCode, exp["code"] as? String, "v\(version) code")
                switch workout.timerType {
                case let .amrap(duration):
                    XCTAssertEqual(duration.seconds, exp["seconds"] as? Int, "v\(version) amrap")
                case let .forTime(cap, countUp):
                    XCTAssertEqual(cap.seconds, exp["cap"] as? Int, "v\(version) cap")
                    XCTAssertEqual(countUp, exp["countUp"] as? Bool, "v\(version) countUp")
                case let .emom(interval, rounds):
                    XCTAssertEqual(interval.seconds, exp["interval"] as? Int, "v\(version) interval")
                    XCTAssertEqual(rounds.value, exp["rounds"] as? Int, "v\(version) emom rounds")
                case let .tabata(work, rest, rounds):
                    XCTAssertEqual(work.seconds, exp["work"] as? Int, "v\(version) work")
                    XCTAssertEqual(rest.seconds, exp["rest"] as? Int, "v\(version) rest")
                    XCTAssertEqual(rounds.value, exp["rounds"] as? Int, "v\(version) tabata rounds")
                }
            }

            let suite = "data-safety-\(version)-\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defaults.removePersistentDomain(forName: suite)
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(data, forKey: "recent_workouts")
            let loaded = RecentWorkoutsStore(defaults: defaults).load()
            XCTAssertEqual(loaded, decoded, "v\(version) RecentWorkoutsStore.load")
        }
    }

    func testSetupVoiceHintAndHealthKeysLoadThroughHEADReaders() throws {
        for version in ["2.0.0", "2.1.0", "2.2.0", "2.2.1"] {
            let dir = Self.fixturesRoot.appendingPathComponent(version)
            let suite = "data-safety-setup-\(version)-\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defaults.removePersistentDomain(forName: suite)
            defer { defaults.removePersistentDomain(forName: suite) }

            for code in ["amrap", "fortime", "emom", "tabata"] {
                let setupData = try Data(contentsOf: dir.appendingPathComponent("setup_\(code).json"))
                let type = try JSONDecoder().decode(TimerType.self, from: setupData)
                XCTAssertEqual(type.typeCode, code, "v\(version) setup \(code)")
                defaults.set(setupData, forKey: "watch_setup_\(code)")
            }

            let memory = SetupMemory(defaults: defaults)
            let expected = try JSONSerialization.jsonObject(
                with: Data(contentsOf: dir.appendingPathComponent("expected.json"))
            ) as? [String: Any]
            let setup = expected?["setup"] as? [String: Any] ?? [:]
            XCTAssertEqual(memory.amrap.seconds, setup["amrapSeconds"] as? Int, "v\(version) amrap")
            XCTAssertEqual(memory.forTime.cap.seconds, setup["forTimeCap"] as? Int, "v\(version) cap")
            XCTAssertEqual(memory.forTime.countUp, setup["forTimeCountUp"] as? Bool, "v\(version) countUp")
            XCTAssertEqual(memory.emom.interval.seconds, setup["emomInterval"] as? Int, "v\(version) emom interval")
            XCTAssertEqual(memory.emom.rounds, setup["emomRounds"] as? Int, "v\(version) emom rounds")
            XCTAssertEqual(memory.tabata.work.seconds, setup["tabataWork"] as? Int, "v\(version) tabata work")
            XCTAssertEqual(memory.tabata.rest.seconds, setup["tabataRest"] as? Int, "v\(version) tabata rest")
            XCTAssertEqual(memory.tabata.rounds, setup["tabataRounds"] as? Int, "v\(version) tabata rounds")

            let prefs = try JSONSerialization.jsonObject(
                with: Data(contentsOf: dir.appendingPathComponent("prefs.json"))
            ) as? [String: Any] ?? [:]
            for (key, value) in prefs {
                defaults.set(value, forKey: key)
            }
            XCTAssertEqual(defaults.string(forKey: "watch_voice_pack"), expected?["voicePack"] as? String)
            XCTAssertEqual(defaults.bool(forKey: "watch_voice_random"), expected?["random"] as? Bool)
            XCTAssertEqual(defaults.bool(forKey: "watch_voice_muted"), expected?["muted"] as? Bool)
            XCTAssertEqual(defaults.bool(forKey: "watch_voice_beeps"), expected?["beeps"] as? Bool)
            XCTAssertEqual(defaults.bool(forKey: "watch_hint_amrap_counted"), expected?["hintCounted"] as? Bool)

            if version == "2.2.0" || version == "2.2.1" {
                let tracker = HealthWorkoutTracker(defaults: defaults)
                XCTAssertEqual(tracker.enabled, expected?["healthTrack"] as? Bool, "v\(version) health")
            }
        }
    }

    func testWatchAudioServiceReadsFixtureVoiceKeysFromStandardDefaults() throws {
        let dir = Self.fixturesRoot.appendingPathComponent("2.2.1")
        let prefs = try JSONSerialization.jsonObject(
            with: Data(contentsOf: dir.appendingPathComponent("prefs.json"))
        ) as? [String: Any] ?? [:]
        let keys = ["watch_voice_pack", "watch_voice_random", "watch_voice_muted", "watch_voice_beeps"]
        var saved: [String: Any?] = [:]
        for key in keys {
            saved[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
        defer {
            for key in keys {
                if let value = saved[key] ?? nil {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
        for (key, value) in prefs where keys.contains(key) {
            UserDefaults.standard.set(value, forKey: key)
        }
        let audio = WatchAudioService()
        XCTAssertEqual(audio.voicePack, .holly)
        XCTAssertFalse(audio.randomizePerCue)
        XCTAssertFalse(audio.muted)
        XCTAssertTrue(audio.beepsOnly)
    }
}
