import 'dart:math';

import 'package:material_ui/material_ui.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/app/app.dart';
import 'package:rohab/app/providers.dart';
import 'package:rohab/glove/mock_glove_service.dart';
import 'package:rohab/onboarding/onboarding.dart';
import 'package:rohab/screens/welcome_screen.dart';
import 'package:rohab/widgets/safety_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<SharedPreferences> pumpFresh(WidgetTester tester, {bool done = false}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(done ? {onboardingDoneKey: true} : {});
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      gloveServiceProvider
          .overrideWithValue(MockGloveService(random: Random(7))),
      sharedPreferencesProvider.overrideWithValue(sp),
    ],
    child: const RohabApp(),
  ));
  await tester.pump();
  await tester.pump();
  return sp;
}

void main() {
  testWidgets('first run shows the guide, four steps, then the measuring flow',
      (tester) async {
    final sp = await pumpFresh(tester);
    expect(find.text('Welcome to Rohab'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsWidgets);
    // No tab bar, no way to wander off during the guide.
    expect(find.text('Progress'), findsNothing);

    await tester.tap(find.byKey(WelcomeScreen.nextKey));
    await tester.pump();
    expect(find.text('How it works'), findsOneWidget);
    expect(find.byKey(WelcomeScreen.backKey), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.nextKey));
    await tester.pump();
    expect(find.text('Before you start'), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.nextKey));
    await tester.pump();
    expect(find.text('Set up your phone'), findsOneWidget);
    expect(find.text('Measure my hands'), findsOneWidget);

    await tester.tap(find.byKey(WelcomeScreen.nextKey));
    await tester.pump();
    await tester.pump();
    expect(isOnboardingDone(sp), isTrue);
    expect(find.text('Welcome to Rohab'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Back goes to the previous step', (tester) async {
    await pumpFresh(tester);
    await tester.tap(find.byKey(WelcomeScreen.nextKey));
    await tester.pump();
    await tester.tap(find.byKey(WelcomeScreen.backKey));
    await tester.pump();
    expect(find.text('Welcome to Rohab'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"Do this later" ends the guide and opens Home', (tester) async {
    final sp = await pumpFresh(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(WelcomeScreen.nextKey));
      await tester.pump();
    }
    await tester.tap(find.byKey(WelcomeScreen.skipKey));
    await tester.pump();
    await tester.pump();
    expect(isOnboardingDone(sp), isTrue);
    expect(find.text('Glove'), findsWidgets); // tab bar is back
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('after the guide, the app opens straight on Home',
      (tester) async {
    await pumpFresh(tester, done: true);
    expect(find.text('Welcome to Rohab'), findsNothing);
    expect(find.text('Exercises'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no glove, no STOP header; it appears once a glove connects',
      (tester) async {
    final glove = await pumpRohab(tester);
    expect(find.byKey(SafetyBanner.stopKey), findsNothing);
    expect(find.text('Glove not connected'), findsNothing);
    await connectFromHome(tester);
    expect(find.byKey(SafetyBanner.stopKey), findsOneWidget);
    await finish(tester, glove);
  });
}
