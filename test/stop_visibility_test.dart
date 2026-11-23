import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/widgets/safety_banner.dart';

import 'helpers.dart';

/// While the glove is active, STOP must be on screen, tappable and whole on
/// every tab, at 200% text, with the keyboard up, on a 360x800 phone. When
/// the glove is idle or absent it is not shown.
void main() {
  for (final tab in ['Today', 'Glove', 'Exercises', 'Progress']) {
    testWidgets(
      'STOP is found, hittable and whole on $tab at 200% text with the keyboard open',
      (tester) async {
        final glove = await pumpRohab(tester);
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        addTearDown(tester.view.resetViewInsets);
        final stop = find.byKey(SafetyBanner.stopKey);
        expect(stop, findsNothing, reason: 'no glove: no STOP');
        glove.connect();
        await tester.pump(const Duration(seconds: 2));
        expect(stop, findsNothing, reason: 'idle: no STOP');
        glove.start();
        await tester.pump(const Duration(seconds: 1));
        await tapTab(tester, tab);
        await tester.pump();

        expect(stop, findsOneWidget);
        expect(
          stop.hitTestable(),
          findsOneWidget,
          reason: 'covered by something',
        );
        final r = tester.getRect(stop);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(r.width, greaterThanOrEqualTo(48));
        expect(r.height, greaterThanOrEqualTo(48));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(screen.width));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(screen.height - 300));
        expect(tester.takeException(), isNull, reason: 'overflow');
        await finish(tester, glove);
      },
    );
  }
}
