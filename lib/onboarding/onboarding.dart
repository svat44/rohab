import 'package:shared_preferences/shared_preferences.dart';

/// First-run guide state. Stored once the person finishes or skips it, so
/// it is shown only the first time.
const onboardingDoneKey = 'onboarding_done_v1';

bool isOnboardingDone(SharedPreferences prefs) =>
    prefs.getBool(onboardingDoneKey) ?? false;

Future<void> markOnboardingDone(SharedPreferences prefs) =>
    prefs.setBool(onboardingDoneKey, true);
