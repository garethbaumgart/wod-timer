import SwiftUI
import WatchKit

@main
struct WODTimerWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

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

/// The WatchKit lifecycle hook the SwiftUI app needs: a workout session
/// handed back after a crash (2.2.0).
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func handleActiveWorkoutRecovery() {
        HealthWorkoutTracker.recoverCrashedSession()
    }
}

#if targetEnvironment(simulator)
/// Screenshot hook for the UX review and store captures (watch simulators
/// can't be tap-driven): `simctl launch <udid> <bundle> --capture <scene>`
/// opens one screen or timer state directly. Simulator builds only, so no
/// device or App Store build contains it.
enum CaptureScene: String, CaseIterable {
    case home, voice, health
    case homeScrolled = "home-scrolled"
    case setupAmrap = "setup-amrap", setupForTime = "setup-fortime"
    case setupEmom = "setup-emom", setupTabata = "setup-tabata"
    case livePrep = "live-prep", liveAmrap = "live-amrap"
    case livePrepForTime = "live-prep-fortime", livePrepEmom = "live-prep-emom"
    case livePrepTabata = "live-prep-tabata"
    case liveForTime = "live-fortime", liveEmom = "live-emom"
    case liveTabataWork = "live-tabata-work", liveTabataRest = "live-tabata-rest"
    case liveTabataNext = "live-tabata-next"
    case pausedForTime = "paused-fortime", pausedEmom = "paused-emom"
    case pausedAmrap = "paused-amrap", pausedTabata = "paused-tabata"
    case finishedForTime = "finished-fortime", timecapForTime = "timecap-fortime"
    case finishedEmom = "finished-emom", stoppedEmom = "stopped-emom"
    case finishedAmrap = "finished-amrap", stoppedAmrap = "stopped-amrap"
    case finishedTabata = "finished-tabata", stoppedTabata = "stopped-tabata"

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
        case .home, .homeScrolled: HomeView()
        case .voice: VoiceSettingsView(viewModel: viewModel)
        case .health: HealthSettingsView(tracker: HealthWorkoutTracker())
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
        case .livePrepForTime: run(Workout.defaultForTime(), 4)
        case .livePrepEmom: run(Workout.defaultEmom(), 4)
        case .livePrepTabata: run(Workout.defaultTabata(), 4)
        case .liveAmrap: run(Workout.defaultAmrap(), 25); viewModel.debugCountRounds(3)
        case .liveForTime: run(Workout.defaultForTime(), 76)
        case .liveEmom: run(Workout.defaultEmom(), 75)
        case .liveTabataWork: run(Workout.defaultTabata(), 16)
        case .liveTabataRest: run(Workout.defaultTabata(), 33)
        case .liveTabataNext: run(Workout.defaultTabata(), 37)
        case .pausedForTime: run(Workout.defaultForTime(), 76); viewModel.pause()
        case .pausedEmom: run(Workout.defaultEmom(), 75); viewModel.pause()
        case .pausedAmrap: run(Workout.defaultAmrap(), 29); viewModel.debugCountRounds(3); viewModel.pause()
        case .pausedTabata: run(Workout.defaultTabata(), 22); viewModel.pause()
        case .finishedForTime: run(Workout.defaultForTime(), 10 + 754); viewModel.debugFinish()
        case .timecapForTime: run(Workout.defaultForTime(), 10 + 1200)
        case .finishedEmom: run(Workout.defaultEmom(), 10 + 600)
        case .stoppedEmom: run(Workout.defaultEmom(), 10 + 125); viewModel.stop()
        case .finishedAmrap:
            run(Workout.defaultAmrap(), 25); viewModel.debugCountRounds(7); viewModel.debugAdvance(seconds: 600)
        case .stoppedAmrap: run(Workout.defaultAmrap(), 29); viewModel.debugCountRounds(3); viewModel.stop()
        case .finishedTabata: run(Workout.defaultTabata(), 10 + 240)
        case .stoppedTabata: run(Workout.defaultTabata(), 10 + 95); viewModel.stop()
        default: break
        }
        ready = true
    }
}
#endif
