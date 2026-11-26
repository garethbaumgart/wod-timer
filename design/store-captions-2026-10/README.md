# Wharf WOD store captions (October 2026)

Direction A of the store presentation review (25 Oct 2026, approved by Gareth): a headline and one
proof line above the real phone screen. Black `#0b0b0f`, white proofs, headlines in the mode colours
(green `#1dff6a`, orange `#ff7a1a`, blue `#35a4ff`, pink `#ff4fa3`), one orange frame with black text.
Fonts are the app's own: Outfit ExtraBold (headline), Outfit Medium (proof). Rendered with
`automation/store-assets/caption_compose.py` from the portfolio repo; nothing is invented, the screens
are the 2.3.1 simulator captures in `raw/` (status bar cropped by the tool).

## Frames

| # | Capture | Headline | Proof |
|---|---------|----------|-------|
| 01 | Tabata WORK 15 | Readable from across the gym (green) | Giant numbers. Voice-coached rounds. Beeps over the music. |
| 02 | Home list | EMOM · AMRAP / Tabata · For Time (black on orange) | Set up in two taps. Round changes called out. |
| 03 | EMOM 55, 2/10 | On your wrist too (pink) | Apple Watch and Wear OS. Hand an EMOM to Apple's Workout app. |
| 04 | For Time setup | Count up or count down (orange) | For Time with a cap. Flip the toggle, hit START. |
| 05 | Tabata setup | Three voices or just beeps (green) | Major, Liam or Holly. Cues play through the silent switch. |
| 06 | Tabata REST 9 | Green means work. Pink means rest. (pink) | Colour-coded phases. A haptic hit on every change. |
| 07 | AMRAP 9:35, 3 rounds | One glance. Time and round. (blue) | Tap the screen to count a round. The bar shows what's left. |
| 08 | Finished For Time 0:16 | Finish. Read it. Go again. (orange) | Your time in giant digits. AGAIN reruns the same workout. |
| 09 | Finished Tabata 2/2 | Stays awake. Stays exact. (green) | Screen stays on. Lock it or switch apps, the clock holds. |
| 10 | Stopped EMOM 2/10 | No account. No ads. No clutter. (pink) | Pick a format, set the time, hit START. Then just work. |

Play shows frames 01 to 08; the App Store set is all ten.

## Outputs

- iOS, 1320x2868: `fastlane/screenshots/en-US/01.png` to `10.png`. They replaced the seven uncaptioned
  phone files in place; `ipad_*.png` and `watch_*.png` are untouched, and `fastlane/screenshots/` holds
  only `en-US`, so the next release replaces just that locale. Staged only: version 2.3.1 is in review
  and nothing was sent to App Store Connect from this branch.
- Play, 1080x1920: `play/en-US/01.png` to `08.png`. Uploaded to the Play en-US listing
  (phoneScreenshots, replacing the previous eight) on 25 Oct 2026. The seven and ten inch tablet sets
  were left as they were.
- Feature graphic, 1024x500: `feature/en-US/feature.png` (icon left, "Readable from across the gym.",
  "Voice-coached EMOM, AMRAP, Tabata and For Time. Phone, tablet, watch."). Uploaded to Play en-US on
  25 Oct 2026.
- `raw/`: the ten `APP_IPHONE_67_*.png` captures and `icon_512.png` the frames are built from.

## Regenerate

From the repo root (paths in `wharfwod.json` are repo-relative):

```
TOOLS=<portfolio>/automation/store-assets
python3 $TOOLS/caption_compose.py --config design/store-captions-2026-10/wharfwod.json --out /tmp/wharf-captions --store both
python3 $TOOLS/caption_compose.py --config design/store-captions-2026-10/wharfwod.json --feature /tmp/wharf-feature   # writes en-US.png
cp /tmp/wharf-captions/ios/en-US/*.png fastlane/screenshots/en-US/
cp /tmp/wharf-captions/play/en-US/0[1-8].png design/store-captions-2026-10/play/en-US/
cp /tmp/wharf-feature/en-US.png design/store-captions-2026-10/feature/en-US/feature.png
python3 $TOOLS/play_screenshots.py replace --package app.mentalmetal.wharfwod --lang en-US --dir design/store-captions-2026-10/play/en-US
python3 $TOOLS/play_screenshots.py replace --package app.mentalmetal.wharfwod --lang en-US --type featureGraphic --dir design/store-captions-2026-10/feature/en-US
```

## Rules kept

No prices, "free", rankings, competitor names or fitness-result claims. Headlines are at most two
lines of about 20 characters (widest: 949 px of the 1320 px canvas). Proofs are at most 60
characters; the ones that Outfit Medium at 46 pt sets wider than about 1000 px are broken into two
lines at a sentence boundary (frame 03's proof measures 1408 px on one line, wider than the canvas).
Outputs are 8-bit sRGB with no alpha, checked with `magick identify`.

## 2.5.2 (19 Nov 2026)

- The live sets are the D6 Whiteboard frames (31 Oct), not the direction-A table above. Since 2.5.2 frame 01 is
  the home screen with all four timers under "For Time. EMOM. AMRAP. Tabata." in the four mode colours (Gareth:
  the first frame must show a screen with all four workout options). It took the closing brand frame's place, so
  both stores stay at eight: opener, the four whiteboards, voices, wrist, finish. Generator: portfolio repo
  `automation/store-assets/preview-concepts/wharfwod/produce.py`.
- `wear/en-US/01.png` to `06.png`: the Wear OS listing set, 454x454 captures of the 2.5.2 watch app from the
  large round emulator (home with the four timers, EMOM setup, EMOM live, Tabata rest, AMRAP with three rounds,
  finished). They replaced the 2.2-era set, which showed the capsules cut by the round edge (Google's Wear
  review, 19 Nov 2026). Upload: `play_screenshots.py batch --item en-US wearScreenshots <dir>`.
- The Wear OS watch in the Play wrist frame (07) is the new EMOM live capture.

## Frame 01 shows Today's WOD (23 Nov 2026)

- Gareth: the first image should be the new home with the mixed feature. Frame 01 (App Store 6.9in and Play phone)
  is now Home with a Today's WOD card that chains all four timers (EMOM 8, For Time 12, AMRAP 10, Tabata 8, rests
  between), under the same four-colour headline; the proof reads "Run one, or chain them into Today's WOD. / No
  account. No ads. No clutter." `raw/APP_IPHONE_67_01.png` is that capture (2.6.1).
- Capture: `UDID=<iPhone 17 Pro Max sim> OUT=<dir> tool/capture_store_home.sh` runs
  `integration_test/store_home_test.dart` (seeds the session, holds Home, grabs it at 9:41).
  `STORE_SESSION=classic` seeds the 2.6.0 mock session instead.
- `fastlane/screenshots-ipad/en-US/`: the 13-inch iPad set the release script uploads (APP_IPAD_PRO_3GEN_129). Its
  `01_home.png` is the same Home on the iPad Pro 13-inch (M5) simulator, with the old capture's status bar and home
  indicator strips pasted on (the iPad simulator ignores the date override; the other nine are the 3 Oct set,
  downloaded from the live listing, kept as they were).

## 2.7.0: every set checked against the app (26 Nov 2026)

Gareth, before the 2.7.0 release: "make sure the preview screens are current and as good as they can be". Every
live set was downloaded (`asc_screenshots.py fetch`, the Play images API) and compared with the app. Found and
fixed:

| Set | Was | Now |
|---|---|---|
| App Store, Apple Watch (8) | 2.0-era captures: no session glyph, the old Home rows | `fastlane/screenshots-watch/en-US/01..08`: eight 368x448 captures of 2.7.0 on the Apple Watch SE 44mm simulator (Home 2x2, EMOM, Tabata work, AMRAP and For Time with the heart rate, EMOM setup, Tabata next, a finished For Time with average and peak) |
| App Store 6.9in and Play phone, frame 07 (wrist) | The Apple Watches showed the 1.3.0 app (a green clock, a round pause button) | The 2.7.0 watch: App Store shows the live EMOM with the heart rate, Home and a finished For Time, and its proof reads "Your heart rate on the timer. / Beeps and taps with your wrist down."; Play keeps its proof and shows Wear OS with the Apple Watch's Tabata and Home |
| App Store, 13-inch iPad (10) | Nine of ten from 3 Oct: small setup dials, no "+ THEN", end screens without the fact tiles | `fastlane/screenshots-ipad/en-US/`: all ten re-captured from 2.6.2 on the iPad Pro 13-inch simulator |
| Play, 7-inch and 10-inch tablets (8 each) | 1.3-era captures, letterboxed under a black band (a 3:4 capture on a 9:16 canvas) | `play-tablet/en-US/01..08`: eight 1440x2560 boards, the phone set's headlines over Pixel Tablet emulator captures of the current app in a slate frame, used for both slots. Board 02 is the tablet's own claim: "The whole gym can read it." |

Frames 01 to 06 and 08 of the phone sets re-rendered pixel-identical to the live ones (0 px at 2% fuzz), the Wear
OS set (2.5.2) and the feature graphic are current, and nothing in them changed.

How each was made:

- **Apple Watch**: build the `WODTimerWatch` scheme for a watch simulator, install
  `Debug-watchsimulator/WODTimerWatch.app` on the Apple Watch SE 44mm (368x448, the `APP_WATCH_SERIES_4` slot) and
  `xcrun simctl launch <udid> app.mentalmetal.wharfwod.watchkitapp --capture <scene> [--heart]`, then
  `simctl io <udid> screenshot`. `--heart` gives the capture a heart rate (164 now, average 152, peak 178). A launch
  with a scene the app does not know starts the real app, whose permission alerts then sit over every later
  capture until the simulator is restarted. The release script uploads the folder (`screenshots-watch` is a slot
  in `ios_release_with_screenshots.sh` since this release; before, the watch set was uploaded by hand).
- **Wrist frame**: generator `preview-concepts/wharfwod` with `WHARF_ASSETS/watch/` holding `1_live_amrap`,
  `2_live_emom`, `3_home`, `4_finished`, `5_live_tabata` (from `screenshots-watch`: 04, 02, 01, 08, 03).
- **iPad and Play tablets**: `integration_test/store_home_test.dart` (frame 01) and
  `integration_test/ux_review_tour_test.dart` (the rest) with a watcher that screenshots at each `MARK_` line.
  The iPad simulator must be in English first (`simctl spawn <udid> defaults write -g AppleLanguages -array en-US`,
  `AppleLocale en_US`, restart): it had been left in Indonesian and the status bar read "Kam 26 Nov". The Pixel
  Tablet emulator had been left in Indonesian too ("09.41", 24-hour end screens): `adb root`,
  `setprop persist.sys.locale en-US`, `setprop ctl.restart zygote`; portrait needs
  `cmd window user-rotation lock 1` (a `wm size` override turns it sideways); SystemUI demo mode sets 9:41.
  A tablet is 10:16 and Play's tablet slots take 9:16 only, so the captures go on boards: the generator's
  `prep_tablet.sh` (paints out the launcher's taskbar) and `produce_tablet.py`, in the portfolio repo's
  `preview-concepts/wharfwod`. The tour's `pumpAndSettle` calls never return on an Android tablet (the rounds
  wheel, DONE back to setup), so they now give up after three seconds (`settle`).
  Upload: `play_screenshots.py batch --item en-US phoneScreenshots <play/en-US> --item en-US sevenInchScreenshots
  <play-tablet/en-US> --item en-US tenInchScreenshots <play-tablet/en-US>` (one commit: Play caps saves per day).
