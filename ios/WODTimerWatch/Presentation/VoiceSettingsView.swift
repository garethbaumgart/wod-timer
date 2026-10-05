import SwiftUI

/// One list, as on the phone: three voices, Random, Beeps only, or Silent
/// (haptics only). Choosing one plays a sample. Under them the sound check
/// (2.2.0): a beep and a line, then where they came out and how loud.
struct VoiceSettingsView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var checkResult = "Plays a beep and a line"

    private var audio: WatchAudioService { viewModel.audio }

    private enum Choice: Equatable { case pack(WatchAudioService.VoicePack), random, beeps, silent }

    private var current: Choice {
        if audio.muted { return .silent }
        if audio.beepsOnly { return .beeps }
        if audio.randomizePerCue { return .random }
        return .pack(audio.voicePack)
    }

    var body: some View {
        List {
            row(.pack(.major), "Major", "Drill sergeant")
            row(.pack(.liam), "Liam", "Male coach")
            row(.pack(.holly), "Holly", "Female coach")
            row(.random, "Random", "A different voice each cue")
            row(.beeps, "Beeps", "No voice, beeps on the count")
            row(.silent, "Silent", "Haptics only")
            Section {
                Button(action: soundCheck) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Sound check")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text(checkResult)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.label)
                        }
                        Spacer()
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Palette.primary)
                    }
                }
            } footer: {
                Text("Cues play through the watch speaker or your headphones. Hear nothing? Turn the Crown in Now Playing to raise the volume.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.label)
            }
        }
        .navigationTitle("Voice")
    }

    private func soundCheck() {
        if audio.muted {
            checkResult = "Silent is on: haptics only"
            return
        }
        audio.playSoundCheck()
        checkResult = audio.outputDescription + (audio.sessionProblem.map { ", \($0)" } ?? "")
    }

    private func row(_ choice: Choice, _ name: String, _ detail: String) -> some View {
        Button {
            select(choice)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.label)
                }
                Spacer()
                if current == choice {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Palette.primary)
                }
            }
        }
    }

    private func select(_ choice: Choice) {
        switch choice {
        case let .pack(pack):
            audio.setMuted(false)
            audio.setBeepsOnly(false)
            audio.setRandomizePerCue(false)
            audio.setVoicePack(pack)
            audio.playLetsGo()
        case .random:
            audio.setMuted(false)
            audio.setBeepsOnly(false)
            audio.setRandomizePerCue(true)
            audio.playLetsGo()
        case .beeps:
            audio.setMuted(false)
            audio.setRandomizePerCue(false)
            audio.setBeepsOnly(true)
            audio.playLetsGo()
        case .silent:
            audio.setMuted(true)
        }
    }
}

#Preview {
    VoiceSettingsView(viewModel: TimerViewModel())
}
