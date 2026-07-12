# Claude Code Instructions

## Project Overview

The Wharf WOD Timer (formerly "WOD Timer") — a CrossFit-style workout timer (AMRAP /
For Time / EMOM / Tabata) with voice cues and a watchOS companion app.
Flutter + Domain-Driven Design. Part of the Mentalmetal portfolio
(bundle id `app.mentalmetal.wharfwod`, free app, no IAP in v1).

## Toolchain

Pinned via FVM — always use `fvm flutter` / `fvm dart`. Version bumps go
through the `mentalmetal-flutter-upgrade` skill only.

## Workflow

- Branch per change, merge to `main` with `--no-ff`, push, delete the branch
  (portfolio convention).
- `fvm flutter analyze` (0 errors/warnings) and `fvm flutter test` must be
  green before merging.
- Timer correctness is sacred: any change to `TimerSession.tick` or
  `TimerNotifier` needs regression tests, including the large-delta
  (app-suspension) cases.

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
