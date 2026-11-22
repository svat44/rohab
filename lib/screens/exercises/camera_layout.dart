import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../camera/hand_tracker.dart';
import '../../debug/diagnostics.dart';
import '../../debug/diagnostics_overlay.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hand_overlay.dart';

/// Camera step. The camera takes all the height the text below it does not
/// need, and shows the whole image (nothing cropped) with the tracked hand
/// drawn on it. [overlay] sits on the camera (countdown, warnings); the
/// text below stays short so it is never pushed off screen.
class CameraPage extends StatelessWidget {
  const CameraPage({
    super.key,
    required this.tracker,
    required this.frame,
    required this.stats,
    required this.children,
    required this.action,
    this.overlay,
    this.diagnostics,
  });

  /// Debug builds only: live tracking numbers instead of the plain stats.
  final DiagnosticsCollector? diagnostics;

  final HandTracker? tracker;
  final ValueListenable<HandFrame?> frame;
  final TrackerStats Function() stats;
  final List<Widget> children;
  final Widget action;

  /// Drawn over the camera, in the top-right corner.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, 0),
            child: _Preview(
                tracker: tracker,
                frame: frame,
                stats: stats,
                overlay: overlay,
                diagnostics: diagnostics),
          ),
        ),
        Flexible(
          flex: 0,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              RohabSpace.s24, RohabSpace.s8, RohabSpace.s24, RohabSpace.s16),
          child: SizedBox(height: RohabSize.touchTarget, child: action),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.tracker,
    required this.frame,
    required this.stats,
    this.overlay,
    this.diagnostics,
  });

  final HandTracker? tracker;
  final ValueListenable<HandFrame?> frame;
  final TrackerStats Function() stats;
  final Widget? overlay;
  final DiagnosticsCollector? diagnostics;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.card);
    final aspect = tracker?.previewAspect ?? 3 / 4;
    return Semantics(
      label: 'Camera view',
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: c.divider, width: RohabShape.border),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (tracker case final t?) t.buildPreview(context),
                  HandOverlay(frame: frame),
                  if (overlay != null)
                    Positioned(
                      top: RohabSpace.s8,
                      right: RohabSpace.s8,
                      child: overlay!,
                    ),
                  if (kDebugMode)
                    Positioned(
                      left: RohabSpace.s8,
                      bottom: RohabSpace.s8,
                      child: diagnostics != null
                          ? DiagnosticsOverlay(collector: diagnostics!)
                          : _DebugStats(stats: stats()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Debug builds only: tracking speed, for on-phone testing.
class _DebugStats extends StatelessWidget {
  const _DebugStats({required this.stats});

  final TrackerStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = stats;
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: RohabSpace.s8, vertical: RohabSpace.s8 / 2),
        child: Text(
          '${s.framesPerSecond.toStringAsFixed(0)} fps · '
          '${s.droppedFrames} dropped',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
