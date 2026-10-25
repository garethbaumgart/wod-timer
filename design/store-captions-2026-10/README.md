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
