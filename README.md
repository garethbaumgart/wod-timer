# The Wharf WOD Timer

A no-fuss workout timer for functional fitness — AMRAP, For Time, EMOM and
Tabata, with voice cues loud enough to hear across a garage gym. Part of the
[Mentalmetal](https://mentalmetal.app) indie portfolio.

Formerly "WOD Timer"; renamed and adopted into the portfolio July 2026
(bundle id `app.mentalmetal.wharfwod`; home-screen name "Wharf WOD").

## What's built (v1)

- **AMRAP** — max rounds in a time cap, counts down
- **For Time** — race the clock, count-up (stopwatch) or count-down
- **EMOM** — every minute (or custom interval) on the minute
- **Tabata** — work/rest intervals with phase previews ("REST in 3s")
- **Voice cues** — 3 recorded voice packs (Major, Liam, Holly) + random mode:
  countdowns, GO, halfway, last round, ten seconds, final 5-4-3-2-1,
  encouragement. Plays through the silent switch (playback audio session).
- **Suspension-proof timing** — wall-clock catch-up: backgrounding the app
  mid-workout can't desync EMOM/Tabata rounds
- **Gym-visible UI** — the "Signal" dark design system, giant timer text,
  explicit landscape layouts, wakelock (honours the setting)
- **watchOS companion app** — standalone timer on the wrist
- Anonymous telemetry: Sentry crash reporting + Aptabase funnel events
  (release builds only, keys via Doppler; no PII, see
  [privacy](https://mentalmetal.app/wharf-wod/privacy))

Deliberately cut from v1: workout presets, recent-workout history, custom
prep countdown (fixed at 10s). The friend's-voice recording/cloning idea is
the future differentiator.

## Development

Toolchain is pinned via FVM (`.fvmrc`) — currently Flutter 3.44.6.

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run                       # dev: telemetry off (no keys)

# With real telemetry keys (Doppler project `wharfwod`):
scripts/with-secrets.sh dev run

fvm flutter test                      # full suite
fvm flutter analyze                   # very_good_analysis, strict
```

## Architecture

Domain-Driven Design with vertical feature slices — see
[ARCHITECTURE.md](./ARCHITECTURE.md). The heart is
`TimerSession` ([lib/features/timer/domain/entities/timer_session.dart]),
an immutable aggregate whose `tick(delta)` consumes any size of time delta
(multi-interval catch-up after app suspension included), returning
`Either<TimerFailure, TimerSession>`.

Stack: Riverpod (codegen), fpdart, freezed, get_it + injectable, go_router,
audioplayers + audio_session, wakelock_plus, sentry_flutter, aptabase_flutter.

## Release

Wired to the shared `mentalmetal-fastlane` lanes (see the portfolio's
setup-deploy / ship skills). Store state is tracked in the portfolio's
`state/apps/wharfwod.yaml`.

## License

MIT
