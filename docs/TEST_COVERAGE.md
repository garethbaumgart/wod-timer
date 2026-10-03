# Wharf WOD 2.0.0: what the tests cover

A behaviour map, not a line count: every user-visible rule in
`docs/SPEC_1.3.1_build.md` (the 2.0.0 spec), per screen and device class,
and the test that holds it. Keep it current: a new rule gets a row and a
test in the same change.

Run everything with `scripts/test_gate.sh` (the release pipeline runs it
before any upload). `--quick` skips the watch simulator.

Device classes: **P** phone portrait 390 x 844, **L** phone landscape
844 x 390 (notched), **T** tablet 1024 x 1366 under TabletScale (laid out
at 600 x 800), **W** Apple Watch (XCTest, logic only; the simulator
`--capture` scenes are the visual check). Large text is 1.6x at 375pt.

Where a row names a file, the path is under `test/` (Flutter) or
`ios/WODTimerWatchTests/Domain/` (watch).

## Numbers (4 Oct 2026, this branch)

| | Before | After |
|---|---|---|
| Flutter tests | 529 | 662 |
| Watch XCTests | 75 | 116 |
| `lib/**` line coverage | 84.7% (2540 / 2999) | 94.8% (2841 / 2998) |
| `timer_notifier.dart` | 84.7% | 94.3% |
| `audio_service.dart` | 0% | 57.3% (the cue rules; the player pool is platform code) |
| `haptic_service.dart` | 0% | 89.8% |
| `settings_page.dart` | 61.7% | 99.2% |
| `app_router.dart` | 36.0% | 100% |
| `app_settings_provider.dart` | 83.1% | 100% |
| `review_prompter.dart` | 61.3% | 77.4% (the store sheet itself is platform code) |

Not covered on purpose: `main.dart` (Sentry and Aptabase boot), the
audioplayers pool and audio_session calls inside `AudioService`,
`StoreReviewRequester` (in_app_review), `value_failures.dart` (unused).

## Timer domain (pure Dart; the same rules in Swift on the watch)

| Behaviour | Flutter | Watch |
|---|---|---|
| Start goes to get ready when prep > 0, straight to running when 0 | `timer_session_test` start | `TimerSessionTests` |
| Pause / resume restore the phase (work, rest, prep); refuse when not allowed | `timer_session_test` pause, resume; `timer_session_edges_test` pause and resume | `TimerSessionTests` |
| Sub-second time survives a pause; 100ms ticks accumulate; a zero delta is a no-op | `timer_session_edges_test` | `testMillisecondAccumulation` |
| AMRAP and For Time complete at the exact boundary, elapsed pinned | `timer_session_test` completion pins; `timer_session_edges_test` For Time | `testAmrapCompletionPinsTheExactDuration`, `testLargeDeltaPastTheEnd...` |
| Catch-up after suspension: EMOM and Tabata consume every interval / phase in one tick and finish in the right round; prep overshoot carries over | `timer_session_test` large-delta catch-up | `testEmomLargeDelta...`, `testTabataLargeDelta...`, `testPrepOvershoot...` |
| EMOM boundary lands on the next round at 0; Tabata with no rest still advances and ends; the last rest is still the last round | `timer_session_edges_test` ticks, Tabata | `testTabataCompletes` |
| timeRemaining per phase, and the paused phase's value | `timer_session_test` timeRemaining while paused | `testTabataPausedMidWorkKeeps...` |
| Progress is the whole-workout fraction (the cue scale) | `timer_session_edges_test` progress | `testProgressComputesCorrectly` |
| Manual complete (FINISH / Stop) keeps elapsed; refused when ready or done | `timer_session_edges_test` FINISH; `timer_session_test` complete | `testManualComplete`, `testCannotComplete...` |
| AMRAP tally: count only while running, correct on the end screen, never below 0 | `timer_notifier_test` live-screen rules; `timer_cues_test` tally guards | `testAmrapRoundTally...`, `testRoundTallyOnlyCounts...` |
| Value objects: duration bounds, clock / phase formats, round counts, workout defaults and totals | `timer_duration_test`, `round_count_test`, `workout_test`, `timer_type_test` | `TimerDurationTests`, `TimerDurationDisplayTests`, `RoundCountTests`, `DomainTypesTests` |

## Timer engine and notifier (ticks, cues, haptics, end states)

| Behaviour | Flutter | Watch |
|---|---|---|
| Engine: ticks, pause keeps elapsed, resume continues, stop resets, dispose closes | `timer_engine_test`, `timer_e2e_test` | (DispatchSourceTimer; exercised through `debugAdvance`) |
| Get ready on the first prep tick; 3, 2, 1 once each with a tap; GO / Let's go with a thump; a 3s prep says Get ready not 3 | `timer_cues_test` get ready and GO | `handleCues` port; `testGetReadyCannotBePaused` |
| Skipping the countdown plays GO, starts at 0, arms the tap cooldown | `timer_cues_test` | `testSkipPrepStartsTheClockAtZero...` |
| AMRAP schedule: motivation at a third, halfway (with a tap), ten seconds, almost there, the final five, then the payoff | `timer_cues_test` AMRAP schedule | ported logic (same thresholds) |
| EMOM: Next round each minute, Last round on the final one, the round cue beats halfway on the same tick, Last round never repeats, catch-up cues once | `timer_cues_test` EMOM schedule; `timer_notifier_test` cue timing | |
| Tabata: Rest with a warning buzz, work and round thumps, Last round as the final work starts, the final rest counts, no Rest cue when rest and round change share a tick | `timer_cues_test` Tabata schedule | |
| One voice cue per tick; ten seconds and the final five measure the whole workout, not the interval | `timer_cues_test`; `timer_notifier_test` whole-workout scale | `testEndSummary...` (whole-workout remaining) |
| Natural end: encouragement (delayed past the final-countdown clip) and a success buzz; **records the review payoff** | `timer_cues_test` AMRAP schedule, "a natural finish records the review payoff moment" | |
| Time cap: end tone and a plain thump, no Good job, no review | `timer_cues_test` For Time; `timer_notifier_test` reaching the cap | `testReachingTheCapIsATimeCap`, `testTimeCapOnlyWhen...` |
| FINISH is a finish (celebrates); Stop is honest (medium tap, no cue, Stopped) | `timer_cues_test` For Time, stop | `testStopIsHonestAndFinishIsAFinish`, `testStopAndFinishAfterTheEndAreNoOps` |
| Pause / resume drive the engine with one tap each; a paused Tabata resumes in its phase | `timer_cues_test` | `testPauseAndResumeKeepATabataInItsPhase` |
| AGAIN restarts the same workout with the cues re-armed; restart is a no-op while running or after reset | `timer_cues_test` | `testRestartOnlyFromTheEndScreen...` |
| Race guards: a tick in flight on pause, double pause, resume after the end, double start, a Stop after the final tick | `timer_notifier_test` race guards | |
| Tap cooldown: a double tap counts one, taps right after GO or resume do not | `timer_notifier_test`; `timer_cues_test` | `testADoubleTapCountsOneRound` |
| Voice setting maps to the audio service (pack, Random, Beeps only, Silent) | `timer_cues_test` voice setting | `VoiceSettingsView` select (not unit-tested; see below) |
| Providers hand out the get_it singletons; the engine is disposed with its scope | `timer_providers_test` | |

## Audio and haptics (real implementations)

| Behaviour | Flutter | Watch |
|---|---|---|
| Every cue plays its clip; 3, 2, 1 spoken and any other number a beep; the beep is one file | `audio_service_test` voice on | `BeepsOnlyTests` (cue set) |
| Voice pack switch; unknown pack is Major; Random picks a real pack per cue | `audio_service_test` | `WatchAudioSettingsTests` |
| Beeps only: timing cues beep, encouragement goes quiet and still succeeds | `audio_service_test` Beeps only | `testTimingCuesBeepAndEncouragementStaysQuiet` |
| Silent: nothing plays, not even the beep; Silent over Beeps only is silent | `audio_service_test` Silent | `play(file:)` guard (not unit-testable without AVAudio) |
| The picker preview plays GO from the asked pack and ignores Silent and Beeps only | `audio_service_test` voice preview | |
| Haptics: each impact's vibration, success / warning / error patterns, Haptics off reports disabled, a failing platform is silent | `haptic_service_test` | (WKInterfaceDevice; not unit-testable) |
| Voice, Random, Silent and Beeps only persist across launches; an unknown stored pack reads Major; volume clamps | | `WatchAudioSettingsTests`, `BeepsOnlyTests` |

## Persistence (app updates never remove stored data)

| Behaviour | Flutter | Watch |
|---|---|---|
| Every key ever written (settings, migration marker, review counters, setup memory, last mode, the counted-round hint) read by every reader, written through every writer, reloaded: same keys, same types, nothing extra | `persistence_golden_test` | |
| Mistyped values read as defaults and are left exactly as found | `persistence_golden_test`; `setup_memory_test` defensive reads; `app_settings_provider_test` clamped voice | `testCorruptDataUnderAKeyReads...`, `testAnUnknownStoredPack...` |
| 1.1.3 and 1.2.x files survive (older goldens) | `setup_memory_test` golden; `app_settings_provider_test` golden | |
| Sound Effects off becomes Silent once (1.3.0 migration); the old key is kept | `app_settings_provider_test` | |
| SetupMemory round trip per mode; `setup_last_mode` written by every save, unknown reads For Time | `setup_memory_test`, `setup_start_test` | `SetupMemoryTests`, `testShapeIgnoresAnotherModeSavedUnderTheKey` |
| Watch: each mode's last setup, the 1.3.0 recents fallback, corrupt data, recents newest-first / deduped / at most three | | `SetupMemoryMoreTests`, `RecentWorkoutsStoreTests` |
| Review counters through SharedPreferences; the quiet policy; the Rate row books the last-asked time | `persistence_golden_test`; `review_prompter_test` | |

## Home

| Behaviour | P | L | T | W |
|---|---|---|---|---|
| Order For Time, EMOM, AMRAP, Tabata; titles white | `home_page_test` | `home_page_test` landscape | `home_page_test` tablet | `testHomeOrderIs...`, `testHomeTitlesAre...` |
| Stacked wordmark (white WHARF, green WOD, pink stop, glow, one header for a screen reader) | `wordmark_test` | | | (image row) |
| Each card: colour bar, name 28 / w900, setup right, 12pt timeline, "total" | `home_page_test` | drops the total, 8pt timeline, fits 844 x 390 | tiles with bar, name, setup, timeline, total | row summary + 6pt timeline: `SetupMemoryTests` summaries, `HomeAndTimelineTests` shapes |
| Cards read the remembered setup; the screen reader hears the setup | `home_page_test` | | | `SetupMemoryMoreTests` |
| Tablet hero = last mode started, For Time by default, unknown falls back; the other three keep order; landscape puts the wordmark left and fits | | | `home_page_test` tablet | |
| Tap selects the mode with a light tap; the settings icon opens Settings | `home_page_test`, `app_router_test` | | `home_page_test` tablet | |
| Large text 1.6x lays out without overflow | `home_page_test` | | | |

## Setup screens

| Behaviour | P | L | T | W |
|---|---|---|---|---|
| Header: back chevron (goes Home), title white 24, grey voice chip flush right | `setup_pages_test` Setup chrome, START slab; `app_router_test` | `setup_pages_test` Landscape | | titles via `.navigationTitle` |
| Android back goes Home, not out of the app | `setup_pages_test` system back | | | |
| START slab edge to edge, 132pt to the bottom, green, 34 / w900; subtitle "10:00 total" (EMOM, Tabata), "Counts up · cap 20:00" (For Time), none (AMRAP); 500ms guard | `setup_pages_test` START slab, START guard; `layout_rules_test` BottomSlab | 96pt slab | 132 under TabletScale | `StartButton` (capsule geometry: `PaletteAndGeometryTests`) |
| No plus / minus anywhere | `setup_pages_test` | | | |
| Bezel: one turn = 60 minutes, 1..60, no wrap past 12 o'clock, ticks in the mode colour, m:00 inside, selection tick per minute, adjustable node | `setup_pages_test` AMRAP, For Time; `setup_start_test` AMRAP | bezel shrinks, line beside it | | Crown 1..60 |
| For Time: COUNT UP / COUNT DOWN switch, remembered, tick on change | `setup_pages_test` For Time; `setup_start_test` For Time | | | `CountDirectionSwitch` |
| Wheels: snapping, 3 rows, selected white on soft, EMOM 15s steps 0:15..10:00 and 1..30, Tabata 5s steps 5s..2:00 and 1..20, label colours (EVERY green, ROUNDS blue; WORK green, REST pink, ROUNDS blue), tick per step, adjustable, limits | `setup_pages_test` EMOM, Tabata, Setup chrome; `setup_start_test` Tabata | wheels in a row, 44pt rows | | Crown steps in `EmomSetupView` / `TabataSetupView` (clamped on load) |
| Tabata "Reset to classic" chip appears only when values drift and resets every wheel | `setup_pages_test` Tabata | | | |
| Timeline under the wheels, redrawn live, centred by rule 2 | `setup_pages_test` Tabata; `layout_rules_screens_test` setup screens | `layout_rules_screens_test` | `layout_rules_screens_test` | |
| START saves exactly the setup shown (every mode) and launches it; `setup_last_mode` recorded | `setup_pages_test` EMOM; `setup_start_test` For Time, Tabata, AMRAP, EMOM | | | `SetupMemoryTests` (save on change) |
| An invalid workout shows its error and launches nothing | `setup_start_test` startSetupWorkout | | | |
| Large text 1.6x, both orientations | `setup_pages_test` Large text | `setup_pages_test` Large text | | |

## Live screens

| Behaviour | P | L | T | W |
|---|---|---|---|---|
| Clock in the workout colour (For Time orange, EMOM pink, AMRAP blue, Tabata work green / rest pink, prep white); paused dims and pulses | `timer_active_page_test` the clock | | | `testLiveColourIsWhiteInGetReady...` |
| Font size set once per workout from its longest value, never refits; minutes never zero-padded; a one-minute phase counts 60 not 1:00; a long rest reads 1:30, 1:00, 59 | `timer_active_page_test` the clock; `timer_active_actions_test` long phase | `timer_active_page_test` landscape | `timer_active_page_test` iPad | `testReferenceClockPerMode`, `testClockText...` |
| Count-up For Time shows elapsed; count-down shows the cap counting down with no second line | `timer_active_page_test` | | | `testClockTextCountsUp...` |
| Phase line: GET READY white; WORK green; REST / LAST REST pink; NEXT · WORK / NEXT · REST in the last five seconds; PAUSED · WORK / REST grey; nothing for other modes | `timer_active_page_test` phase word | | | `testPhaseWordNames...`, `testPausedPhaseWord...` |
| Second slot: TAP TO COUNT until the first ever count, then "N ROUNDS" (0 reads 0); EMOM / Tabata "2/10"; count-up For Time "CAP 20:00"; prep "TAP TO SKIP" | `timer_active_page_test` the second number | | | `ScoreSlot` (glyph inset per workout: `testScoreSlotInset...`) |
| Timeline = progress: finished parts filled, current filling, rest on the track; centred by rule 2 on every screen and device | `timer_active_page_test` the timeline; `layout_rules_screens_test` live | `layout_rules_screens_test` | `layout_rules_screens_test` | `testFillFractions...`, `TimelineZone` |
| Rule 1, no jumping: 9:59 -> 10:00, 10 -> 9, TAP TO COUNT -> 1 ROUNDS, 2/8 -> 3/8 with WORK -> REST move nothing else | `layout_rules_screens_test` live | | | fixed slots (`PhaseLine`, `ScoreSlot.height`) |
| Slab: PAUSE alone; For Time FINISH (white) | PAUSE; paused HOLD TO STOP | RESUME (workout colour); prep HOLD TO STOP alone; colours and widths | `timer_active_page_test` the slab | `timer_active_page_test` landscape | `timer_active_page_test` iPad | `CapsuleGeometry` |
| HOLD TO STOP: fills red over 0.8s, a short press hints and moves nothing, cancel rewinds quietly, disabled ignores the finger, long-press action for a screen reader | `timer_active_page_test` the slab; `hold_to_stop_cell_test`; `timer_active_actions_test` semantics | | | `HoldToStopCapsule` (gesture, not unit-tested) |
| Canvas taps: prep tap skips, AMRAP tap counts (700ms cooldown), paused tap resumes; taps on the slab never count | `timer_active_page_test`; `timer_active_actions_test` actions | | | `canvasTap` + `testADoubleTapCountsOneRound` |
| FINISH logs a finish; RESUME resumes; Stop in prep goes back to setup; AGAIN restarts from the top | `timer_active_actions_test` actions | | | `TimerViewModelMoreRulesTests` |
| Android back: prep -> setup; running / resting -> nothing; paused -> hint on HOLD TO STOP; end -> DONE; not started -> setup | `timer_active_page_test` back gesture; `timer_active_actions_test` Android back; `app_router_test` | | | (watch has no back on a live screen) |
| What a screen reader hears per state (live region, clock, second line, named slab buttons) | `timer_active_actions_test` what a screen reader hears | | | `BigClock` / `HoldToStopCapsule` labels |
| Wakelock held while the page is open; immersive system UI | `screen_harness` channel mock (behaviour asserted by the page tests running) | | | |
| Large text 1.6x: live, paused, end and prep, every mode | `timer_active_actions_test` large text | `timer_active_actions_test` large text | | |

## End screens

| Behaviour | P | L | T | W |
|---|---|---|---|---|
| Word Finished / Stopped / Time cap white 30; config line "TABATA · 8 × 20s / 10s" etc. | `timer_active_page_test` completion | | | `testEndSummary...`, `testConfigLinePerMode` |
| For Time: hero the time, TIME; time cap: word only, full timeline | `timer_active_page_test` completion; `layout_rules_screens_test` end | `layout_rules_screens_test` | `layout_rules_screens_test` | `testEndSummaryForTimeAndTimeCap` |
| EMOM / Tabata: "r/N" (stopped) or "N/N" (finished), ROUNDS, "2:05 total" | `timer_active_page_test` completion | | | `testEndSummaryEmom...`, `testEndSummaryTabata...` |
| AMRAP: rounds wheel 0..999, selected blue, neighbours dim, drag and adjustable node fix the count, as big as the EMOM hero | `timer_active_page_test` completion; `rounds_wheel_test`; `layout_rules_screens_test` | `timer_active_page_test` (fits sideways) | `layout_rules_screens_test` | `RoundsWheel` (Crown; `testAmrapRoundTally...`) |
| Timeline filled to where it ended, centred by rule 2 | `layout_rules_screens_test` end screens | same | same | `TimelineZone` |
| Slab AGAIN (workout colour, black) | DONE (soft, white); DONE lands on this mode's setup with the workout remembered | `timer_active_page_test` completion | | | `CompletedView` capsules |
| Natural end records the review payoff; Stop and time cap do not | `timer_cues_test` | | | |

## Settings and voice picker

| Behaviour | Test |
|---|---|
| Flat list of six rows in order, 17pt white / grey, version footer (and its loading / failed forms) | `settings_page_test`, `settings_actions_test` version footer |
| Android back goes Home | `settings_page_test` |
| Orientation: sheet with Auto / Portrait / Landscape, icons, the check on the current one; a choice persists, asks the OS for exactly those orientations, closes | `settings_actions_test` Orientation |
| Haptics switch persists and reaches the haptic service; a stored off opens off | `settings_actions_test` Haptics |
| Voice picker: preview leads each row, check trails it, play previews without selecting, the row selects and closes, the silent-switch line, large text | `settings_page_test` Voice picker |
| Rate row opens the store page once and books the quiet period, never the automatic sheet | `settings_page_test`, `review_prompter_test` |
| Send feedback opens mail to support with the subject; Privacy policy opens the site page outside the app | `settings_actions_test` links |

## Theme, layout rules, telemetry, routing

| Behaviour | Test |
|---|---|
| Colours have one meaning each (the AppColors table) | asserted on every screen above; `PaletteAndGeometryTests` on the watch |
| TabletScale: phones untouched, tablets laid out at a 600pt shortest side, 1.75 cap | `tablet_scale_test` |
| GlyphInk metrics, CentredTimeline placement, BottomSlab heights and home-indicator clearance | `layout_rules_test` |
| Bundled Outfit fonts, no runtime fetch | `bundled_fonts_test` |
| Telemetry is a silent no-op outside a release build with a key | `telemetry_test` |
| Every route, bad mode and bad path placeholders, not-started live route, chevrons and the settings icon | `app_router_test`, `widget_test` |
| The simulator capture scenes cover every state (store and review captures) | `testCaptureScenesCoverEveryState` (watch); `integration_test/ux_review_tour_test.dart` (phone, run by hand) |

## Judged not worth automating (and why)

- The watch's SwiftUI layouts (fits on 40 to 46mm without scrolling, the
  capsule clipping, Crown focus). No view-testing framework in the
  target; the `--capture` scenes plus a look at the four sizes are the
  check, and `testCaptureScenesCoverEveryState` keeps the scene list
  honest.
- `WatchHapticService` and the AVAudioPlayer path in `WatchAudioService`:
  thin wrappers over WatchKit and AVFoundation with no logic to hold.
- `main.dart`: Sentry and Aptabase initialisation under compile-time
  keys; a unit test would only mock both SDKs.
- The audioplayers pool and audio_session ducking inside `AudioService`:
  platform plumbing; the decision layer above it (which file, when) is
  fully covered through the test sink.
- `StoreReviewRequester` and `PrefsReviewStore` wiring to `in_app_review`:
  the OS decides whether the sheet shows.
- Pixel-exact appearance: the layout rules are checked structurally
  (rects, colours, glyph-measured gaps) rather than with goldens, which
  break on every font or engine update without catching behaviour.
