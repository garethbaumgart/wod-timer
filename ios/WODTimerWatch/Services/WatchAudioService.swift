import AVFoundation
import Foundation
import Observation

/// Audio service for watchOS that plays voice cue MP3s from bundled resources.
/// Uses AVAudioPlayer for playback with ducking of other audio.
@Observable
final class WatchAudioService {

    // MARK: - Configuration

    enum VoicePack: String, CaseIterable, Codable {
        case major
        case liam
        case holly
    }

    private(set) var voicePack: VoicePack = .major
    private(set) var randomizePerCue: Bool = false
    private(set) var muted: Bool = false
    /// Beeps only (1.3.1, as on the phone): no voice; the timing cues
    /// (countdown, GO, rest, intervals, last round, the end) beep and the
    /// encouragement goes quiet.
    private(set) var beepsOnly: Bool = false
    private(set) var volume: Float = 1.0

    // MARK: - Internal

    @ObservationIgnored
    private var player: AVAudioPlayer?
    @ObservationIgnored
    private let playbackDelegate = AudioPlaybackDelegate()

    // Persisted since 1.3.0 (the choice used to reset on every launch).
    // Additive keys; a missing or unknown value reads as the default.
    @ObservationIgnored private let defaults = UserDefaults.standard
    private static let packKey = "watch_voice_pack"
    private static let randomKey = "watch_voice_random"
    private static let mutedKey = "watch_voice_muted"
    private static let beepsKey = "watch_voice_beeps"

    /// Cues that beep in Beeps only mode: the phone's beep-fallback set.
    static let beepCues: Set<String> = [
        "countdown_1", "countdown_2", "countdown_3", "countdown_go", "rest",
        "complete", "interval", "get_ready", "ten_seconds", "last_round",
        "next_round", "final_countdown", "lets_go",
    ]

    init() {
        if let raw = defaults.string(forKey: Self.packKey), let pack = VoicePack(rawValue: raw) {
            voicePack = pack
        }
        randomizePerCue = defaults.bool(forKey: Self.randomKey)
        muted = defaults.bool(forKey: Self.mutedKey)
        beepsOnly = defaults.bool(forKey: Self.beepsKey)
        configureAudioSession()
    }

    deinit {
        deactivateAudioSession()
    }

    // MARK: - Configuration

    func setVoicePack(_ pack: VoicePack) {
        voicePack = pack
        defaults.set(pack.rawValue, forKey: Self.packKey)
    }

    func setRandomizePerCue(_ enabled: Bool) {
        randomizePerCue = enabled
        defaults.set(enabled, forKey: Self.randomKey)
    }

    func setMuted(_ muted: Bool) {
        self.muted = muted
        defaults.set(muted, forKey: Self.mutedKey)
    }

    func setBeepsOnly(_ enabled: Bool) {
        beepsOnly = enabled
        defaults.set(enabled, forKey: Self.beepsKey)
    }

    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
    }

    // MARK: - Voice Cues

    func playCountdown(_ number: Int) {
        play(file: "countdown_\(number)")
    }

    func playGo() {
        play(file: "countdown_go")
    }

    func playRest() {
        play(file: "rest")
    }

    func playHalfway() {
        play(file: "halfway")
    }

    func playGetReady() {
        play(file: "get_ready")
    }

    func playTenSeconds() {
        play(file: "ten_seconds")
    }

    func playLastRound() {
        play(file: "last_round")
    }

    func playKeepGoing() {
        play(file: "keep_going")
    }

    func playGoodJob() {
        play(file: "good_job")
    }

    func playNextRound() {
        play(file: "next_round")
    }

    func playFinalCountdown() {
        play(file: "final_countdown")
    }

    func playLetsGo() {
        play(file: "lets_go")
    }

    func playComeOn() {
        play(file: "come_on")
    }

    func playAlmostThere() {
        play(file: "almost_there")
    }

    func playThatsIt() {
        play(file: "thats_it")
    }

    // MARK: - Private

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
        } catch {
            // Audio session config is non-critical
        }
    }

    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Plays a voice cue audio file.
    /// Uses a single player instance — a new cue replaces any in-progress cue.
    /// This is intentional: voice cues are short and sequential, so overlapping
    /// playback would sound garbled. The timer logic already prevents rapid-fire
    /// triggers via the `voiceCuePlayed` flag.
    private func play(file: String, ext: String = "mp3", forcePack: VoicePack? = nil) {
        guard !muted else { return }

        if beepsOnly {
            guard Self.beepCues.contains(file) else { return }
            playResource(Bundle.main.url(forResource: "beep", withExtension: "m4a", subdirectory: "audio/major"))
            return
        }

        let pack: VoicePack
        if let forcePack {
            pack = forcePack
        } else if randomizePerCue {
            pack = VoicePack.allCases.randomElement() ?? .major
        } else {
            pack = voicePack
        }

        // Audio files are in the bundle under audio/{pack}/{file}.{ext}
        playResource(Bundle.main.url(forResource: file, withExtension: ext, subdirectory: "audio/\(pack.rawValue)"))
    }

    private func playResource(_ url: URL?) {
        guard let url else { return }
        do {
            activateAudioSession()
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.volume = volume
            newPlayer.delegate = playbackDelegate
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer // retain
        } catch {
            // Audio playback is non-critical on watch
        }
    }
}

// MARK: - Playback Delegate

/// Deactivates the audio session when playback finishes to conserve battery.
private final class AudioPlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
