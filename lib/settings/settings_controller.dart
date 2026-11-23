import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers.dart';

/// App-wide text size. Multiplies the phone's own text size setting.
enum TextSize {
  normal('Standard', 1.0),
  large('Large', 1.25),
  largest('Extra large', 1.5);

  const TextSize(this.label, this.scale);

  final String label;
  final double scale;

  static TextSize fromName(String? name) => TextSize.values.firstWhere(
    (s) => s.name == name,
    orElse: () => TextSize.normal,
  );
}

const _textSizeKey = 'rohab.settings.textSize.v1';

final textSizeProvider = NotifierProvider<TextSizeNotifier, TextSize>(
  TextSizeNotifier.new,
);

class TextSizeNotifier extends Notifier<TextSize> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  TextSize build() => TextSize.fromName(
    ref.watch(sharedPreferencesProvider).getString(_textSizeKey),
  );

  Future<void> set(TextSize size) async {
    state = size;
    await _prefs.setString(_textSizeKey, size.name);
  }
}
