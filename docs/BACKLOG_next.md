# Next release backlog

Notes from Gareth to pick up in the next set of changes. Add new items here as they come in; move each into the release's plan or spec when the build starts.

## Settings > Voice

- **Major is a Drill Sergeant, not a CrossFit coach** (4 Oct 2026). Keep the order of the voice options exactly as it is; only the description changes.
  - Phone and tablet: `lib/core/presentation/widgets/voice_picker_sheet.dart:30` shows `Major (CrossFit Coach)`; change to `Major (Drill Sergeant)`.
  - Watch: `ios/WODTimerWatch/Presentation/VoiceSettingsView.swift:21` shows `"Major", "CrossFit coach"`; change the subtitle to `Drill sergeant`, matching the other rows' case.
  - Doc comment: `lib/core/application/providers/app_settings_provider.dart:12`.
  - Tests that find the old text: `test/core/presentation/pages/settings_page_test.dart:281` and `integration_test/ux_review_tour_test.dart:205`.
  - Spelling: "Sergeant".

## Beeps and voice cues (awaiting Gareth's pick)

- Match the SmartWOD pattern Gareth recorded on 4 Oct 2026: three low beeps (about 435.5 Hz) in the last three seconds of every phase, then a high beep (about 1031 Hz) exactly on the change, with the voice line starting on it. The beeps sit about 5.5 dB above the voice.
- Mocks for each voice pack are on the Sound match page: https://claude.ai/artifact/TtVVu6nQ2gSkU7s3BHM29n
- Missing voice lines to record if wanted: "Round 2", "Round 3", and so on, plus "Well done".

## Already merged, waiting to ship

- 2.0.1: the rating-prompt fix from the coverage audit. Ship it once 2.0.0 is approved on iOS.
