/// Pain check rules. Pure Dart.
library;

import 'program_settings.dart';

enum PainAdvice {
  /// Go ahead.
  ok,

  /// Pain is high before starting: advise rest today.
  restToday,

  /// Pain rose during the session: advise rest and telling the therapist.
  painRose,
}

class PainRules {
  PainRules._();

  static PainAdvice before(int score, ProgramSettings s) =>
      score >= s.painHighLimit ? PainAdvice.restToday : PainAdvice.ok;

  static PainAdvice after(int before, int after, ProgramSettings s) =>
      after - before >= s.painRiseLimit ? PainAdvice.painRose : PainAdvice.ok;
}
