import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../exercises/camera_exercise_controller.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_area.dart';
import '../../widgets/countdown_number.dart';
import '../../widgets/level_bar.dart';
import '../../widgets/photo_slot.dart';

/// One camera exercise, steps 1-5: instructions, hand check, range
/// calibration (once per session), exercise, done.
class CameraExerciseFlow extends ConsumerStatefulWidget {
  const CameraExerciseFlow({super.key, required this.exerciseId});

  final String exerciseId;

  static const primaryKey = Key('flow-primary');
  static const secondaryKey = Key('flow-secondary');
  static const repsKey = Key('flow-reps');
  static const instructionKey = Key('flow-instruction');

  @override
  ConsumerState<CameraExerciseFlow> createState() => _CameraExerciseFlowState();
}

class _CameraExerciseFlowState extends ConsumerState<CameraExerciseFlow>
    with WidgetsBindingObserver {
  late final CameraExercise _exercise;
  late final CameraExerciseController _controller;

  @override
  void initState() {
    super.initState();
    _exercise =
        ExerciseCatalog.byId(widget.exerciseId) ?? ExerciseCatalog.openClose;
    final ranges = ref.read(cameraSessionRangesProvider.notifier);
    _controller = CameraExerciseController(
      exercise: _exercise,
      trackerFactory: ref.read(handTrackerFactoryProvider),
      permission: ref.read(cameraPermissionProvider),
      repository: ref.read(exerciseSessionRepositoryProvider),
      loadRange: () {
        final r = ref.read(cameraSessionRangesProvider);
        return _exercise.usesSpread ? r.spread : r.openness;
      },
      saveRange: _exercise.usesSpread ? ranges.setSpread : ranges.setOpenness,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Settings: try again without another tap.
    if (state == AppLifecycleState.resumed) _controller.recheckPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose(); // stops the camera
    super.dispose();
  }

  void _back() => context.go(Routes.cameraExercises);

  void _finishSession() {
    ref.read(cameraSessionRangesProvider.notifier).clear();
    context.go(Routes.cameraExercises);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
    final c = _controller;
    final t = Theme.of(context).textTheme;
    final back = _TextAction(label: 'Back', onPressed: _back);
    final cancel = _TextAction(label: 'Cancel', onPressed: _back);

    switch (c.step) {
      case FlowStep.instructions:
        return _Page(
          secondary: back,
          primary: _PrimaryAction(label: 'Start', onPressed: c.start),
          children: [
            // Steps first so they are visible without scrolling; the photo
            // follows.
            _ExerciseIndicator(current: _exercise),
            const SizedBox(height: RohabSpace.s8),
            Text(_exercise.title, style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            for (var i = 0; i < _exercise.steps.length; i++)
              _NumberedStep(number: i + 1, text: _exercise.steps[i]),
            Text('Target: ${_exercise.targetReps} ${_exercise.repUnit}',
                style: t.labelLarge),
            const SizedBox(height: RohabSpace.s24),
            PhotoSlot(caption: '${_exercise.title}, right hand shown.'),
            const SizedBox(height: RohabSpace.s24),
          ],
        );

      case FlowStep.permission:
        return _Page(
          secondary: back,
          primary:
              _PrimaryAction(label: 'Allow camera', onPressed: c.allowCamera),
          children: [
            Text('Camera', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(
              'Rohab uses the camera to count your exercises. '
              'Video stays on this phone and is never saved.',
              style: t.bodyLarge,
            ),
          ],
        );

      case FlowStep.permissionDenied:
        return _Page(
          secondary: back,
          primary:
              _PrimaryAction(label: 'Open settings', onPressed: c.openSettings),
          children: [
            Text('Camera is off for Rohab', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(
              'To count your exercises, turn on camera access for Rohab in '
              'Settings, then come back here.',
              style: t.bodyLarge,
            ),
          ],
        );

      case FlowStep.starting:
        return _Page(
          secondary: back,
          children: [Text('Starting the camera.', style: t.bodyLarge)],
        );

      case FlowStep.cameraError:
        return _Page(
          secondary: back,
          primary: _PrimaryAction(label: 'Try again', onPressed: c.retryCamera),
          children: [
            Text(c.errorMessage ?? 'The camera could not start.',
                style: t.bodyLarge),
          ],
        );

      case FlowStep.handCheck:
        return _CameraPage(
          controller: c,
          action: cancel,
          children: [
            _Instruction('Hold your hand inside the frame.'),
          ],
        );

      case FlowStep.calibrate:
        final high = c.calibratePhase == CalibratePhase.high;
        final text = _exercise.usesSpread
            ? (high
                ? 'Spread your fingers as wide as you can.'
                : 'Now bring your fingers together.')
            : (high ? 'Open your hand as wide as you can.' : 'Now make a fist.');
        return _CameraPage(
          controller: c,
          action: cancel,
          children: [
            _Instruction(text),
            const SizedBox(height: RohabSpace.s8),
            CountdownNumber(seconds: c.secondsLeft),
          ],
        );

      case FlowStep.calibrationFailed:
        return _CameraPage(
          controller: c,
          action: Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: RohabSpace.s8),
              Expanded(
                child: _PrimaryAction(
                    label: 'Try again', onPressed: c.retryCalibration),
              ),
            ],
          ),
          children: [
            Text(
              "We couldn't measure your hand. Keep your whole hand in the "
              'frame and try again.',
              style: t.bodyLarge,
            ),
          ],
        );

      case FlowStep.exercise:
        return _CameraPage(
          controller: c,
          action: _TextAction(label: 'End exercise', onPressed: c.endExercise),
          children: [_ExerciseReadout(controller: c, exercise: _exercise)],
        );

      case FlowStep.done:
        final s = c.summary!;
        final next = ExerciseCatalog.after(_exercise.id);
        final unit = s.reps == 1 ? _exercise.repUnit.replaceAll(RegExp(r's$'), '') : _exercise.repUnit;
        final headline = s.completed
            ? 'Exercise complete. ${s.reps} $unit.'
            : 'Exercise ended. ${s.reps} $unit.';
        return _Page(
          secondary: next == null
              ? null
              : _TextAction(label: 'Finish', onPressed: _finishSession),
          primary: next == null
              ? _PrimaryAction(label: 'Finish', onPressed: _finishSession)
              : _PrimaryAction(
                  label: 'Next exercise',
                  onPressed: () =>
                      context.pushReplacement(Routes.cameraExercise(next.id)),
                ),
          children: [
            _ExerciseIndicator(current: _exercise),
            const SizedBox(height: RohabSpace.s24),
            Semantics(
              liveRegion: true,
              child: Text(headline, style: t.headlineMedium),
            ),
            const SizedBox(height: RohabSpace.s16),
            if (s.rangeMin != null && s.rangeMax != null)
              Text(
                'Range: ${s.rangeMin!.round()}%–${s.rangeMax!.round()}%',
                style: t.bodyLarge,
              ),
            if (s.reps == 0) ...[
              const SizedBox(height: RohabSpace.s8),
              Text('Nothing was saved.', style: t.labelMedium),
            ],
          ],
        );
    }
  }
}

/// Text-only step: scrolling content and the fixed action area.
class _Page extends StatelessWidget {
  const _Page({required this.children, this.secondary, this.primary});

  final List<Widget> children;
  final Widget? secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
            children: children,
          ),
        ),
        ActionArea(secondary: secondary, primary: primary),
      ],
    );
  }
}

/// Camera step: preview in the top 55 %, then content, then one action row.
class _CameraPage extends StatelessWidget {
  const _CameraPage({
    required this.controller,
    required this.children,
    required this.action,
  });

  static const previewShare = 0.55;

  final CameraExerciseController controller;
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
              child: _Preview(controller: controller),
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
  const _Preview({required this.controller});

  final CameraExerciseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tracker = controller.tracker;
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
              if (tracker != null) tracker.buildPreview(context),
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
                  child: _DebugStats(controller: controller),
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
  const _DebugStats({required this.controller});

  final CameraExerciseController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = controller.stats;
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

class _ExerciseReadout extends StatelessWidget {
  const _ExerciseReadout({required this.controller, required this.exercise});

  static const fingerNames = ['index', 'middle', 'ring', 'little'];

  final CameraExerciseController controller;
  final CameraExercise exercise;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = controller;
    final measure = exercise.usesSpread ? 'Spread' : 'Openness';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: '${c.reps} of ${exercise.targetReps} ${exercise.repUnit}',
          excludeSemantics: true,
          // Scales down rather than overflowing at large text sizes.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${c.reps} of ${exercise.targetReps}',
                    key: CameraExerciseFlow.repsKey, style: t.displayLarge),
                const SizedBox(width: RohabSpace.s8),
                Text(exercise.repUnit, style: t.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: RohabSpace.s16),
        // The message and the bar share one fixed-height slot, so the
        // layout doesn't jump when the hand is lost.
        SizedBox(
          height: RohabType.label * 1.25 + RohabSpace.s8 + LevelBar.barHeight,
          child: c.handLost
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hold your hand inside the frame.',
                      style: t.labelLarge),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      exercise.kind == ExerciseKind.fingerTouches
                          ? 'Next: ${fingerNames[c.expectedFinger]} finger'
                          : '$measure ${c.percent.round()}%',
                      style: t.labelMedium
                          ?.copyWith(color: context.colors.text),
                    ),
                    const SizedBox(height: RohabSpace.s8),
                    LevelBar(
                      value: c.percent / 100,
                      semanticsLabel: measure,
                      semanticsValue: '${c.percent.round()} percent',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// "1 · 2 · 3" — where this exercise sits in the set.
class _ExerciseIndicator extends StatelessWidget {
  const _ExerciseIndicator({required this.current});

  final CameraExercise current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme.labelLarge!;
    final all = ExerciseCatalog.all;
    final index = all.indexOf(current);
    return Semantics(
      label: 'Exercise ${index + 1} of ${all.length}',
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: [
        for (var i = 0; i < all.length; i++) ...[
          if (i > 0) TextSpan(text: ' · ', style: t.copyWith(color: c.secondary)),
          TextSpan(
            text: '${i + 1}',
            style: i == index
                ? t.copyWith(color: c.accent, fontWeight: FontWeight.w700)
                : t.copyWith(color: c.secondary, fontWeight: FontWeight.w500),
          ),
        ],
      ])),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: RohabSpace.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: RohabSpace.s32,
            child: Text('$number.', style: t.labelLarge),
          ),
          Expanded(child: Text(text, style: t.bodyLarge)),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Text(text,
            key: CameraExerciseFlow.instructionKey,
            style: Theme.of(context).textTheme.titleLarge),
      );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: CameraExerciseFlow.primaryKey,
        onPressed: onPressed,
        child: Text(label),
      );
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        key: CameraExerciseFlow.secondaryKey,
        onPressed: onPressed,
        child: Text(label),
      );
}
