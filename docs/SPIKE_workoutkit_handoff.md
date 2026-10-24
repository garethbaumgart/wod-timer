# Spike: hand the WOD to Apple's Workout app (24 Oct 2026)

Gareth's steer (24 Oct 2026): Wharf WOD is a complement to the Workout app,
not a second recorder. Running the timer inside our own HKWorkoutSession
gives the record heart rate and calories, but it ends whatever the athlete
was already recording in Workout, and the Workout app's own experience
(live heart rate, rings, Return to App, Always On) is not ours to copy.
Apple Watch runs one workout session at a time, and background taps and
sounds need a session, so the only way to complement the Workout app with
the full experience is to let it run the WOD: WorkoutKit.

## What the spike does

- `Services/WorkoutHandoff.swift` composes the remembered EMOM or Tabata as
  a WorkoutKit `CustomWorkout` (indoor; Tabata as HIIT, EMOM as functional
  strength training, the same mapping as the Health session), under the
  Home summary as its name ("EMOM 10 × 1:00", "Tabata 8 × 20s / 10s"), and
  calls `WorkoutPlan.openInWorkoutApp()` (watchOS 10+).
- `Presentation/Setup/RunInWorkoutButton.swift`: a second capsule, RUN IN
  WORKOUT, under START on the EMOM and Tabata setups. A failure shows as
  one line under it.
- AMRAP and For Time are not composed yet (one timed step and an open step
  with the cap as its goal, once the verdict is in).
- Nothing starts a session of ours. The Health row and "Track workouts" are
  unchanged for the START path.

## What to feel on the Ultra (TestFlight)

1. Home > EMOM, set 10 × 1:00, tap RUN IN WORKOUT. The Workout app should
   open on the plan and offer Start.
2. Start it. Wrist down: does the Workout app stay on the dimmed screen and
   come back on wrist raise (it has Return to App on by default)?
3. The interval change: Apple's own tap and chime at each minute, the Up
   Next view by turning the Crown, heart rate a page away.
4. Tabata 8 × 20s / 10s the same: work and rest alternate with alerts.
5. End it in the Workout app. Fitness should list "EMOM 10 × 1:00" as a
   Functional Strength Training workout with heart rate and calories.
6. Start a Functional Strength workout in the Workout app first, then RUN
   IN WORKOUT: the Workout app asks about the one already running (one
   recording at a time is Apple's rule, not ours).

What decides the default: whether Apple's interval alerts feel firm enough
at the change (our 3-2-1 beeps and GO double knock are gone in this mode)
and whether losing our live screen matters in practice.

## Wear OS (same branch)

Timer only by default. The foreground service and ongoing-activity chip keep
the timer alive, visible and tapping on their own; the Health Services
exercise, which ends whatever Fitbit or Samsung Health is recording, is
now the opt-in "Record as workout" switch (key `wear_record_workout`,
missing = off). Recording also checks for another app's exercise before
GO and stays out of its way (`getCurrentExerciseInfoAsync`).

## Tests

- `ios/WODTimerWatchTests/Application/WorkoutHandoffTests.swift`: the
  blocks per mode, activity types, names, the modes not composed yet.
- `android/wear/.../services/ExerciseTrackerPolicyTest.kt`: the default, the
  old key ignored, the one-exercise guard.
