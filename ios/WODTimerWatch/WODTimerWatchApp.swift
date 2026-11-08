import SwiftUI
import UserNotifications
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

/// The WatchKit lifecycle hooks the SwiftUI app needs: a workout session
/// handed back after a crash (2.2.0), and the wrist alerts' delegate (2.4.0).
final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // A fresh launch has no timer, so alerts a killed run left behind
        // could only ring stale.
        center.removeAllPendingNotificationRequests()
    }

    func handleActiveWorkoutRecovery() {
        HealthWorkoutTracker.recoverCrashedSession()
    }

    /// On screen, or frontmost with the wrist down, the app plays its own
    /// cue for the change, so the alert for it stays quiet. Only once the
    /// app is gone (suspended, the face back) does the system show them.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }
}

#if targetEnvironment(simulator)
/// Screenshot hook for the UX review and store captures (watch simulators
/// can't be tap-driven): `simctl launch <udid> <bundle> --capture <scene>`
/// opens one screen or timer state directly. Simulator builds only, so no
/// device or App Store build contains it.
enum CaptureScene: String, CaseIterable {
    case home, voice, health
    /// 2.4.0: the Health page after another app took the session.
    case healthLost = "health-lost"
    /// 2.4.0: the Return to App page.
    case stayOnScreen = "stay-on-screen"
    case homeScrolled = "home-scrolled"
    case setupAmrap = "setup-amrap", setupForTime = "setup-fortime"
    case setupEmom = "setup-emom", setupTabata = "setup-tabata"
    /// Spike: opens the remembered EMOM / Tabata in the Workout app on appear.
    case handoffEmom = "handoff-emom", handoffTabata = "handoff-tabata"
    case livePrep = "live-prep", liveAmrap = "live-amrap"
    case livePrepForTime = "live-prep-fortime", livePrepEmom = "live-prep-emom"
    case livePrepTabata = "live-prep-tabata"
    case liveForTime = "live-fortime", liveEmom = "live-emom"
    /// 2.4.0: the live EMOM with no session, alerts standing in / nothing.
    case liveEmomAlerts = "live-emom-alerts", liveEmomNoCues = "live-emom-nocues"
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
    @State private var viewModel: TimerViewModel
    @State private var ready = false

    init(scene: CaptureScene) {
        self.scene = scene
        _viewModel = State(initialValue: Self.viewModel(for: scene))
    }

    /// The alert scenes run with no session, so the glyph shows the alerts
    /// standing in, or nothing when they are not allowed.
    static func viewModel(for scene: CaptureScene) -> TimerViewModel {
        switch scene {
        case .liveEmomAlerts:
            TimerViewModel(tracker: NoopWorkoutTracker(status: .off), alerts: NoopWristAlerts(status: .allowed))
        case .liveEmomNoCues:
            TimerViewModel(tracker: NoopWorkoutTracker(status: .takenOver), alerts: NoopWristAlerts(status: .denied))
        default:
            TimerViewModel()
        }
    }

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
        case .health: HealthSettingsView(tracker: HealthWorkoutTracker(), alerts: NoopWristAlerts())
        case .healthLost:
            HealthSettingsView(
                tracker: HealthWorkoutTracker(), alerts: NoopWristAlerts(),
                note: "Last workout: another app's workout took over at 4:12; the alerts carried on."
            )
        case .stayOnScreen: StayOnScreenView()
        case .setupAmrap: AmrapSetupView(viewModel: viewModel)
        case .setupForTime: ForTimeSetupView(viewModel: viewModel)
        case .setupEmom, .handoffEmom: EmomSetupView(viewModel: viewModel)
        case .setupTabata, .handoffTabata: TabataSetupView(viewModel: viewModel)
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
        case .handoffEmom, .handoffTabata:
            let type = SetupMemory().type(scene == .handoffEmom ? "emom" : "tabata")
            Task { @MainActor in
                do { try await WorkoutHandoff.open(type) } catch { print("handoff: \(WorkoutHandoff.message(for: error))") }
            }
        case .livePrep: run(Workout.defaultAmrap(), 4)
        case .livePrepForTime: run(Workout.defaultForTime(), 4)
        case .livePrepEmom: run(Workout.defaultEmom(), 4)
        case .livePrepTabata: run(Workout.defaultTabata(), 4)
        case .liveAmrap: run(Workout.defaultAmrap(), 25); viewModel.debugCountRounds(3)
        case .liveForTime: run(Workout.defaultForTime(), 76)
        case .liveEmom, .liveEmomAlerts, .liveEmomNoCues: run(Workout.defaultEmom(), 75)
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
