import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rohab/camera/hand_tracker.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/theme/app_theme.dart';
import 'package:rohab/widgets/hand_overlay.dart';

HandFrame frameAt(double wristX, {required bool mirrored}) => HandFrame(
      landmarks: [
        for (var i = 0; i < 21; i++) Point3(i == 0 ? wristX : 0.5, 0.5, 0),
      ],
      handedness: Handedness.left,
      confidence: 0.9,
      timestamp: Duration.zero,
      mirrored: mirrored,
    );

Future<void> pumpOverlay(WidgetTester tester, HandFrame f) =>
    tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: HandOverlay(frame: ValueNotifier<HandFrame?>(f)),
        ),
      ),
    ));

void main() {
  // The preview is a mirror. A hand on the left of an unmirrored frame (the
  // Android sensor buffer) appears on the right of the preview; the iOS
  // plugin already mirrors the frame, so x is used as is. Getting this
  // wrong draws the hand on the opposite side of the real one.
  testWidgets('unmirrored frame (Android): x is flipped onto the preview',
      (tester) async {
    await pumpOverlay(tester, frameAt(0.2, mirrored: false));
    expect(
      find.descendant(
          of: find.byType(HandOverlay), matching: find.byType(CustomPaint)),
      paints..circle(x: 80, y: 50),
    );
  });

  testWidgets('already mirrored frame (iOS): x is used as is', (tester) async {
    await pumpOverlay(tester, frameAt(0.2, mirrored: true));
    expect(
      find.descendant(
          of: find.byType(HandOverlay), matching: find.byType(CustomPaint)),
      paints..circle(x: 20, y: 50),
    );
  });
}
