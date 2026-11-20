/// Therapist PIN checks. Pure Dart.
///
/// This keeps a patient from changing their plan by accident. It is not
/// security: the hash is not cryptographic and the PIN is short.
library;

class TherapistPin {
  TherapistPin._();

  static const length = 4;

  static bool isValid(String pin) =>
      pin.length == length && RegExp(r'^\d+$').hasMatch(pin);

  /// FNV-1a 32-bit of a salted PIN, as hex.
  static String hash(String pin) {
    var h = 0x811c9dc5;
    for (final c in 'rohab-therapist:$pin'.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static bool matches(String pin, String? storedHash) =>
      storedHash != null && hash(pin) == storedHash;
}
