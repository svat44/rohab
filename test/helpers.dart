import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/app/app.dart';
import 'package:rohab/app/providers.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/screens/home_screen.dart';
import 'package:rohab/widgets/bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Launches the full app on a 390 x 844 phone with a seeded mock glove.
Future<MockGloveService> pumpRohab(
  WidgetTester tester, {
  MockGloveService? glove,
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final g = glove ?? MockGloveService(random: Random(7));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gloveServiceProvider.overrideWithValue(g),
      sharedPreferencesProvider.overrideWithValue(sp),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
    child: const RohabApp(),
  ));
  await tester.pump();
  return g;
}

/// Unmounts the app and stops the mock's timers.
Future<void> finish(WidgetTester tester, MockGloveService glove) async {
  await tester.pumpWidget(const SizedBox());
  glove.dispose();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byType(BottomNav), matching: find.text(label)));
  await tester.pump();
}

Future<void> connectFromHome(WidgetTester tester) async {
  await tester.tap(find.byKey(HomeScreen.primaryButtonKey));
  await tester.pump(MockGloveService.connectDelay);
}
