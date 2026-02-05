import SwiftUI

/// Voice pack selection and audio settings for the watch.
struct VoiceSettingsView: View {
    @Bindable var viewModel: TimerViewModel

    private var audio: WatchAudioService { viewModel.audio }

    var body: some View {
        List {
            Section("Voice") {
                voiceRow(.major, label: "Major", description: "Crossfit coach")
                voiceRow(.liam, label: "Liam", description: "British gentleman")
                voiceRow(.holly, label: "Holly", description: "Female voice")
            }

            Section {
                Toggle("Randomize", isOn: Binding(
                    get: { audio.randomizePerCue },
                    set: { audio.setRandomizePerCue($0) }
                ))
                .font(.system(size: 13))
            } footer: {
                Text("Randomly pick a voice for each cue")
                    .font(.system(size: 9))
            }

            Section {
                Toggle("Mute Voice", isOn: Binding(
                    get: { audio.muted },
                    set: { audio.setMuted($0) }
                ))
                .font(.system(size: 13))
            } footer: {
                Text("Haptics still play when muted")
                    .font(.system(size: 9))
            }
        }
        .navigationTitle("Voice")
    }

    private func voiceRow(
        _ pack: WatchAudioService.VoicePack,
        label: String,
        description: String
    ) -> some View {
        Button {
            audio.setVoicePack(pack)
            audio.setRandomizePerCue(false)
            // Play a sample so user hears the voice (skip if muted)
            if !audio.muted {
                audio.playLetsGo()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if audio.voicePack == pack && !audio.randomizePerCue {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                }
            }
        }
    }
}

#Preview {
    VoiceSettingsView(viewModel: TimerViewModel())
}
