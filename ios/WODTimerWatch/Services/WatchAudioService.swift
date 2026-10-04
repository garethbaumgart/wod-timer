import AVFoundation
import Foundation
import Observation

/// Audio service for watchOS that plays voice cue MP3s and the gym-timer
/// beeps from bundled resources.
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
    /// Beeps only (1.3.1, as on the phone): no voice. Since 2.1.0 the beeps
    /// carry every countdown and change in every mode, so Beeps only is the
    /// beeps with the voice taken away.
    private(set) var beepsOnly: Bool = false
    private(set) var volume: Float = 1.0

    // MARK: - Internal

    @ObservationIgnored
    private var player: AVAudioPlayer?
    /// One prepared player per beep, kept apart from the voice player so the
    /// high beep and the line that starts on it play together.
    @ObservationIgnored
    private var beepPlayers: [String: AVAudioPlayer] = [:]
    @ObservationIgnored
    private let playbackDelegate = AudioPlaybackDelegate()

    /// What was played, newest last ("beep:low_3", "voice:rest"), for tests.
    @ObservationIgnored
    private(set) var cueLog: [String] = []

    // Persisted since 1.3.0 (the choice used to reset on every launch).
    // Additive keys; a missing or unknown value reads as the default.
    @ObservationIgnored private let defaults = UserDefaults.standard
    private static let packKey = "watch_voice_pack"
    private static let randomKey = "watch_voice_random"
    private static let mutedKey = "watch_voice_muted"
    private static let beepsKey = "watch_voice_beeps"

    init() {
        if let raw = defaults.string(forKey: Self.packKey), let pack = VoicePack(rawValue: raw) {
            voicePack = pack
        }
        randomizePerCue = defaults.bool(forKey: Self.randomKey)
        muted = defaults.bool(forKey: Self.mutedKey)
        beepsOnly = defaults.bool(forKey: Self.beepsKey)
        configureAudioSession()
        playbackDelegate.isIdle = { [weak self] in
            guard let self else { return true }
            return !(self.player?.isPlaying ?? false) && !self.beepPlayers.values.contains { $0.isPlaying }
        }
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

    // MARK: - Beeps (2.1.0)

    /// The low beep with [secondsLeft] (3, 2, 1) to go in a phase. The
    /// gym-timer pattern, as on the phone: three low beeps, then the high
    /// beep on the change with the voice line on top.
    func playLowBeep(_ secondsLeft: Int) {
        playBeep("low_\(min(3, max(1, secondsLeft)))")
    }

    /// The high beep on every change: start, round, rest, work, end.
    func playHighBeep() {
        playBeep("high")
    }

    // MARK: - Voice Cues

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

    func playComplete() {
        play(file: "complete")
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
        guard !muted, !beepsOnly else { return }

        let pack: VoicePack
        if let forcePack {
            pack = forcePack
        } else if randomizePerCue {
            pack = VoicePack.allCases.randomElement() ?? .major
        } else {
            pack = voicePack
        }

        // Audio files are in the bundle under audio/{pack}/{file}.{ext}
        log("voice:\(file)")
        playResource(Bundle.main.url(forResource: file, withExtension: ext, subdirectory: "audio/\(pack.rawValue)"))
    }

    /// Plays a beep from audio/beeps/ on its own prepared player, so it never
    /// cuts off the voice. Only Silent mutes the beeps.
    private func playBeep(_ name: String) {
        guard !muted else { return }
        log("beep:\(name)")
        let beep: AVAudioPlayer
        if let prepared = beepPlayers[name] {
            beep = prepared
        } else {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "audio/beeps"),
                  let made = try? AVAudioPlayer(contentsOf: url) else { return }
            made.delegate = playbackDelegate
            made.prepareToPlay()
            beepPlayers[name] = made
            beep = made
        }
        activateAudioSession()
        beep.volume = volume
        beep.currentTime = 0
        beep.play()
    }

    private func log(_ cue: String) {
        cueLog.append(cue)
        if cueLog.count > 400 { cueLog.removeFirst(cueLog.count - 400) }
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

/// Deactivates the audio session when playback finishes to conserve battery,
/// once nothing else is still playing (a beep ends while its line goes on).
private final class AudioPlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    var isIdle: () -> Bool = { true }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        guard isIdle() else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
