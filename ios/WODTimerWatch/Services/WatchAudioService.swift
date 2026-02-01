import AVFoundation
import Foundation

/// Audio service for watchOS that plays voice cue MP3s from bundled resources.
/// Uses AVAudioPlayer for playback with ducking of other audio.
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

    private var player: AVAudioPlayer?

    init() {
        configureAudioSession()
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

    func playBeep() {
        // Beep is always from major pack, .m4a format
        play(file: "beep", ext: "m4a", forcePack: .major)
    }

    func playCountdown(_ number: Int) {
        play(file: "countdown_\(number)")
    }

    func playGo() {
        play(file: "countdown_go")
    }

    func playRest() {
        play(file: "rest")
    }

    func playComplete() {
        play(file: "complete")
    }

    func playHalfway() {
        play(file: "halfway")
    }

    func playIntervalStart() {
        play(file: "interval")
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

    func playNoRep() {
        play(file: "no_rep")
    }

    // MARK: - Private

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true)
        } catch {
            // Audio session config is non-critical
        }
    }

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
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.volume = volume
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer // retain
        } catch {
            // Audio playback is non-critical on watch
        }
    }
}
