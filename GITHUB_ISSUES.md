# WOD Timer - GitHub Issues

> Issues organized by Epic, following DDD architecture from ARCHITECTURE.md
> Full issue details available at: https://github.com/garethbaumgart/wod-timer/issues

## Epic Summary

| Epic | Issues | Description |
|------|--------|-------------|
| **1. Foundation** | #1-6 | Project setup, DI, core value objects, theme, routing |
| **2. Timer Domain** | #7-11 | Timer types, Workout entity, TimerSession aggregate, failures |
| **3. Timer Infrastructure** | #12-15 | Storage, repository impl, audio service, timer engine |
| **4. Timer Application** | #16-19 | Use cases, Timer BLoC, Presets BLoC |
| **5. Timer Presentation** | #20-27 | All UI screens (setup, active, complete, home, presets) |
| **6. Audio Cues** | #28-30 | Sound assets, cue triggers, audio settings |
| **7. Polish & Quality** | #31-36 | Haptics, background support, onboarding, testing, performance |
| **8. Voice Packs (Future)** | #37-39 | Domain model, recording UI, AI voice cloning |

## Sprint Plan

| Sprint | Focus | Issues |
|--------|-------|--------|
| **Sprint 1** | Foundation | #1-6 |
| **Sprint 2** | Domain & Infrastructure | #7-15 |
| **Sprint 3** | Application Layer | #16-19 |
| **Sprint 4** | UI - Setup Pages | #20-23, #26 |
| **Sprint 5** | UI - Active Timer | #24-25, #27 |
| **Sprint 6** | Audio & Polish | #28-36 |
| **Future** | Voice Packs | #37-39 |

## Issue Dependencies

```
#1 (Project Setup) ✅
 └── #2 (DI Setup)
      └── #3 (Core Value Objects)
           └── #4 (Core Failures)
                └── #7 (Timer Types)
                     └── #8 (Workout Entity)
                          └── #9 (Timer Session)

#5 (Theme) + #6 (Routing) → UI Issues (#20-27)
#9 + #14 (Audio) + #15 (Timer Engine) → #16 (Use Cases) → #18 (Timer BLoC)
#12 (Storage) → #13 (Repository) → #17 (Preset Use Cases) → #19 (Presets BLoC)
```

## Current Status

- [x] Issue #1: Initialize Flutter Project with DDD Structure
- [ ] Issue #2: Configure Dependency Injection
- [ ] Issue #3: Create Core Domain Value Objects
- [ ] Issue #4: Create Core Failure Types
- [ ] Issue #5: Set Up App Theme and Design System
- [ ] Issue #6: Set Up Navigation/Routing

See https://github.com/garethbaumgart/wod-timer/issues for full details.
