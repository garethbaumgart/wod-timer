# Claude Code Instructions

## Project Overview

The Wharf WOD Timer (formerly "WOD Timer") — a CrossFit-style workout timer (AMRAP /
For Time / EMOM / Tabata) with voice cues and a watchOS companion app.
Flutter + Domain-Driven Design. Part of the Mentalmetal portfolio
(bundle id `app.mentalmetal.wharfwod`, free app, no IAP in v1).

## Toolchain

Pinned via FVM — always use `fvm flutter` / `fvm dart`. Version bumps go
through the `mentalmetal-flutter-upgrade` skill only.

Codegen is **not** the FVM pin. `dart run build_runner` hangs on Flutter
3.47.7 (`analyzer` 7.6.0 missing `visitDotShorthandPropertyAccess`). Run
it on Flutter **3.44.9** and commit `*.g.dart`, `*.freezed.dart`, and
`lib/injection.config.dart` whenever annotated sources change. CI
regenerates on 3.44.9 and fails on a real diff (registration order in
`injection.config.dart` is ignored). See `docs/data-safety.md`.

## Workflow

- Branch per change, merge to `main` with `--no-ff`, push, delete the branch
  (portfolio convention).
- `fvm flutter analyze` (0 errors/warnings) and `fvm flutter test` must be
  green before merging.
- Timer correctness is sacred: any change to `TimerSession.tick` or
  `TimerNotifier` needs regression tests, including the large-delta
  (app-suspension) cases.
- Any change to persisted data (schema, prefs keys, file formats) must add a
  new fixture + data-safety test in the same PR; run `scripts/data_safety_gate.sh`
  before any release; never edit an old fixture to make a test pass.
  See `docs/data-safety.md`.

## Architecture

See `ARCHITECTURE.md` for DDD patterns, layer responsibilities, and coding
conventions. v1 has no persistence layer beyond SharedPreferences for
settings — presets/history were cut; don't resurrect dead code without a
feature decision.

## Portfolio context

- Telemetry: Sentry + Aptabase, keys via Doppler project `wharfwod`
  (`scripts/with-secrets.sh`), release-mode gated, no PII.
- Store state of record: `mentalmetal-app-bootstrap/state/apps/wharfwod.yaml`.
- Ship via the `mentalmetal-ship` skill once setup-deploy has been run.
