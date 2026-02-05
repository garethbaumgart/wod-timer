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
    private(set) var volume: Float = 1.0

    // MARK: - Internal

    @ObservationIgnored
    private var player: AVAudioPlayer?
    @ObservationIgnored
    private let playbackDelegate = AudioPlaybackDelegate()

    init() {
        configureAudioSession()
    }

    deinit {
        deactivateAudioSession()
    }

    // MARK: - Configuration

    func setVoicePack(_ pack: VoicePack) {
        voicePack = pack
    }

    func setRandomizePerCue(_ enabled: Bool) {
        randomizePerCue = enabled
    }

    func setMuted(_ muted: Bool) {
        self.muted = muted
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

        let pack: VoicePack
        if let forcePack {
            pack = forcePack
        } else if randomizePerCue {
            pack = VoicePack.allCases.randomElement() ?? .major
        } else {
            pack = voicePack
        }

        // Audio files are in the bundle under audio/{pack}/{file}.{ext}
        guard let url = Bundle.main.url(forResource: file, withExtension: ext, subdirectory: "audio/\(pack.rawValue)") else {
            return
        }

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
