# Splash art

The launch screen is the home hero: the `WOD.` wordmark (white `WOD`, accent
`#00FF88` period) centred on `AppColors.backgroundDark` (`#050510`). The app is
dark-locked, so there is no light variant.

`splash.png` (1024x1024) is the iOS/Android source; `splash_android12.png`
(1152x1152, smaller mark) keeps the whole wordmark inside the circle Android
12+ masks the splash icon to.

Both are generated from the bundled Outfit ExtraBold so the wordmark matches the
in-app hero exactly:

```sh
F=assets/fonts/Outfit-ExtraBold.ttf
magick -background none -fill white -font $F -pointsize 420 -kerning -10 label:"WOD" /tmp/w.png
magick -background none -fill "#00FF88" -font $F -pointsize 420 label:"." /tmp/d.png
# trim the period's left side bearing so the dot sits as tight as it does on the home screen
magick /tmp/d.png -gravity West -background none -chop 12x0 /tmp/d-tight.png
magick /tmp/w.png /tmp/d-tight.png +append -trim +repage -background none /tmp/wordmark.png
magick /tmp/wordmark.png -resize 880x -background none -gravity center -extent 1024x1024 assets/splash/splash.png
magick /tmp/wordmark.png -resize 640x -background none -gravity center -extent 1152x1152 assets/splash/splash_android12.png
```

Then write the native assets (both platforms), per the `flutter_native_splash`
block in `pubspec.yaml`:

```sh
fvm dart run flutter_native_splash:create
```

That command also rewrites `web/` (disabled here via `web: false`) and wants to
reformat `ios/Runner/Info.plist`; the reformat is whitespace plus a redundant
`UIStatusBarHidden: false`, so it is deliberately not committed.
