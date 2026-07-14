import SwiftUI

/// Home screen: timer type list + recent workouts.
struct HomeView: View {
    @State private var viewModel = TimerViewModel()
    @State private var selectedWorkout: Workout?
    @State private var showingTimer = false

    var body: some View {
        NavigationStack {
            List {
                // Timer types
                Section {
                    timerTypeRow(
                        icon: "repeat",
                        label: "AMRAP",
                        subtitle: "Max rounds in time",
                        color: .green,
                        destination: AmrapSetupView(viewModel: viewModel)
                    )
                    timerTypeRow(
                        icon: "stopwatch",
                        label: "FOR TIME",
                        subtitle: "Race the clock",
                        color: .blue,
                        destination: ForTimeSetupView(viewModel: viewModel)
                    )
                    timerTypeRow(
                        icon: "alarm",
                        label: "EMOM",
                        subtitle: "Every min on the min",
                        color: .orange,
                        destination: EmomSetupView(viewModel: viewModel)
                    )
                    timerTypeRow(
                        icon: "flame",
                        label: "TABATA",
                        subtitle: "Work / Rest intervals",
                        color: .purple,
                        destination: TabataSetupView(viewModel: viewModel)
                    )
                }

                // Voice settings
                Section {
                    NavigationLink {
                        VoiceSettingsView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 16))
                                .foregroundStyle(.teal)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Voice")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(voiceSubtitle)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Recent workouts
                let recents = viewModel.recentsStore.load()
                if !recents.isEmpty {
                    Section("Recent") {
                        ForEach(recents) { workout in
                            Button {
                                selectedWorkout = workout
                                showingTimer = true
                                viewModel.start(workout: workout)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.teal)
                                    Text("\(workout.timerType.estimatedDuration.formatted) total")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.carousel)
            .navigationTitle("Wharf WOD")
            .navigationDestination(isPresented: $showingTimer) {
                ActiveTimerView(viewModel: viewModel)
            }
            .onAppear {
                // Promo-footage hook: `simctl launch ... --promo-autostart`
                // starts a default AMRAP after a beat so the simulator can be
                // recorded without driving the UI. No effect in normal use.
                if CommandLine.arguments.contains("--promo-autostart") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.start(workout: WorkoutFactory.defaultAmrap())
                        showingTimer = true
                    }
                }
            }
        }
    }

    private var voiceSubtitle: String {
        let audio = viewModel.audio
        if audio.muted { return "Muted" }
        if audio.randomizePerCue { return "Random" }
        return audio.voicePack.rawValue.capitalized
    }

    private func timerTypeRow<Destination: View>(
        icon: String,
        label: String,
        subtitle: String,
        color: Color,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
