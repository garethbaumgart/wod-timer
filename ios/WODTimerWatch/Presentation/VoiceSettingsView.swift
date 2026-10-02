import SwiftUI

/// One list: three voices, Random, or Silent (haptics only). Choosing a
/// voice plays a sample.
struct VoiceSettingsView: View {
    @Bindable var viewModel: TimerViewModel

    private var audio: WatchAudioService { viewModel.audio }

    private enum Choice: Equatable { case pack(WatchAudioService.VoicePack), random, silent }

    private var current: Choice {
        if audio.muted { return .silent }
        if audio.randomizePerCue { return .random }
        return .pack(audio.voicePack)
    }

    var body: some View {
        List {
            row(.pack(.major), "Major", "CrossFit coach")
            row(.pack(.liam), "Liam", "Old British man")
            row(.pack(.holly), "Holly", "Female coach")
            row(.random, "Random", "A different voice each cue")
            row(.silent, "Silent", "Haptics only")
        }
        .navigationTitle("Voice")
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
            audio.setRandomizePerCue(false)
            audio.setVoicePack(pack)
            audio.playLetsGo()
        case .random:
            audio.setMuted(false)
            audio.setRandomizePerCue(true)
            audio.playLetsGo()
        case .silent:
            audio.setMuted(true)
        }
    }
}

#Preview {
    VoiceSettingsView(viewModel: TimerViewModel())
}
