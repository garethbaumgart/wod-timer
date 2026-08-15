import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Locks font loading to the Outfit files bundled under `assets/fonts/`.
///
/// google_fonts fetches any font it hasn't cached from fonts.gstatic.com at
/// runtime. With no connectivity (gym basements, airplane mode) that fetch
/// throws and takes the whole session down — Sentry WHARFWOD-1, 19 fatal
/// crashes on 9 Aug 2026. All nine Outfit weights ship as assets, so every
/// variant the app can request resolves locally and the network path is
/// never reached.
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Bundled font files must ship with their license (SIL OFL 1.1).
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Outfit'], license);
  });
}
