import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../camera/hand_tracker.dart';
import '../../theme/app_theme.dart';

/// Camera step: preview in the top 55 %, then content, then one action row.
class CameraPage extends StatelessWidget {
  const CameraPage({
    super.key,
    required this.tracker,
    required this.stats,
    required this.children,
    required this.action,
    this.previewShare = 0.55,
  });

  /// Share of the height for the camera: 55 % while exercising; less on
  /// steps that only need to see the hand, so their text fits.
  final double previewShare;

  final HandTracker? tracker;
  final TrackerStats Function() stats;
  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: constraints.maxHeight * previewShare,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
              child: _Preview(tracker: tracker, stats: stats),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, 0),
              children: children,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                RohabSpace.s24, RohabSpace.s8, RohabSpace.s24, RohabSpace.s16),
            child: SizedBox(height: RohabSize.touchTarget, child: action),
          ),
        ],
      );
    });
  }
}

/// Live camera with a plain outline frame showing where to hold the hand.
class _Preview extends StatelessWidget {
  const _Preview({required this.tracker, required this.stats});

  final HandTracker? tracker;
  final TrackerStats Function() stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.radius);
    return Semantics(
      label: 'Camera view',
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
              Padding(
                padding: const EdgeInsets.all(RohabSpace.s24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: c.accent, width: RohabShape.strongBorder),
                    borderRadius: radius,
                  ),
                ),
              ),
              if (kDebugMode)
                Positioned(
                  left: RohabSpace.s8,
                  top: RohabSpace.s8,
                  child: _DebugStats(stats: stats()),
                ),
            ],
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

