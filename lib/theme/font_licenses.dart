import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart' show rootBundle;

/// Registers the SIL Open Font License of each bundled font, so they show up
/// in About > licenses. Fonts are bundled, never fetched at runtime.
void registerFontLicenses() {
  const fonts = {
    'Atkinson Hyperlegible Next': 'assets/fonts/atkinson/OFL.txt',
    'Source Sans 3': 'assets/fonts/sourcesans3/OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final e in fonts.entries) {
      final text = await rootBundle.loadString(e.value);
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}
