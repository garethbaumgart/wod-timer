import SwiftUI

@main
struct WODTimerWatchApp: App {
    var body: some Scene {
        WindowGroup {
            #if targetEnvironment(simulator)
            if let scene = CaptureScene.fromLaunchArguments() {
                CaptureRoot(scene: scene)
            } else {
                HomeView()
            }
            #else
            HomeView()
            #endif
        }
    }
}

#if targetEnvironment(simulator)
/// Screenshot hook for the UX review and store captures (watch simulators
/// can't be tap-driven): `simctl launch <udid> <bundle> --capture <scene>`
/// opens one screen or timer state directly. Simulator builds only, so no
/// device or App Store build contains it.
enum CaptureScene: String {
    case home, voice
    case setupAmrap = "setup-amrap", setupForTime = "setup-fortime"
    case setupEmom = "setup-emom", setupTabata = "setup-tabata"
    case livePrep = "live-prep", liveAmrap = "live-amrap"
    case liveForTime = "live-fortime", liveEmom = "live-emom"
    case liveTabataWork = "live-tabata-work", liveTabataRest = "live-tabata-rest"
    case liveTabataNext = "live-tabata-next"
    case pausedAmrap = "paused-amrap", pausedTabata = "paused-tabata"
    case stoppedAmrap = "stopped-amrap", finishedForTime = "finished-fortime"
    case finishedTabata = "finished-tabata", finishedAmrap = "finished-amrap"

    static func fromLaunchArguments() -> CaptureScene? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--capture"), i + 1 < args.count else { return nil }
        return CaptureScene(rawValue: args[i + 1])
    }
}

struct CaptureRoot: View {
    let scene: CaptureScene
    @State private var viewModel = TimerViewModel()
    @State private var ready = false

    var body: some View {
        NavigationStack {
            content
        }
        .onAppear(perform: prepare)
    }

    @ViewBuilder private var content: some View {
        switch scene {
        case .home: HomeView()
        case .voice: VoiceSettingsView(viewModel: viewModel)
        case .setupAmrap: AmrapSetupView(viewModel: viewModel)
        case .setupForTime: ForTimeSetupView(viewModel: viewModel)
        case .setupEmom: EmomSetupView(viewModel: viewModel)
        case .setupTabata: TabataSetupView(viewModel: viewModel)
        default:
            if ready { ActiveTimerView(viewModel: viewModel) } else { Color.black }
        }
    }

    private func prepare() {
        func run(_ workout: Workout, _ seconds: Int) {
            viewModel.start(workout: workout)
            viewModel.debugAdvance(seconds: seconds)
        }
        switch scene {
        case .voice:
            viewModel.audio.setMuted(false)
            viewModel.audio.setBeepsOnly(false)
            viewModel.audio.setRandomizePerCue(false)
            viewModel.audio.setVoicePack(.major)
        case .livePrep: run(Workout.defaultAmrap(), 4)
        case .liveAmrap: run(Workout.defaultAmrap(), 25); viewModel.debugCountRounds(3)
        case .liveForTime: run(Workout.defaultForTime(), 76)
        case .liveEmom: run(Workout.defaultEmom(), 75)
        case .liveTabataWork: run(Workout.defaultTabata(), 16)
        case .liveTabataRest: run(Workout.defaultTabata(), 33)
        case .liveTabataNext: run(Workout.defaultTabata(), 37)
        case .pausedAmrap: run(Workout.defaultAmrap(), 29); viewModel.debugCountRounds(3); viewModel.pause()
        case .pausedTabata: run(Workout.defaultTabata(), 22); viewModel.pause()
        case .stoppedAmrap: run(Workout.defaultAmrap(), 29); viewModel.debugCountRounds(3); viewModel.stop()
        case .finishedForTime: run(Workout.defaultForTime(), 10 + 754); viewModel.debugFinish()
        case .finishedTabata: run(Workout.defaultTabata(), 10 + 240)
        case .finishedAmrap: run(Workout.defaultAmrap(), 10 + 600)
        default: break
        }
        ready = true
    }
}
#endif
