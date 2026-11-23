import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../debug/diagnostics.dart';
import '../../debug/diagnostics_overlay.dart';
import '../../exercises/camera_exercise_controller.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_providers.dart';
import '../../exercises/hand_distance.dart';
import '../../program/daily_plan.dart';
import '../../program/program_providers.dart';
import '../progress/overview.dart';
import '../progress/progress_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeuo.dart';
import '../../widgets/action_area.dart';
import '../../widgets/countdown_number.dart';
import '../../widgets/immersive.dart';
import '../../widgets/level_bar.dart';
import '../../widgets/photo_slot.dart';
import '../../widgets/rohab_widgets.dart';
import 'camera_layout.dart';

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
    with WidgetsBindingObserver, ImmersiveScreen<CameraExerciseFlow> {
  late final CameraExercise _exercise;
  late final CameraExerciseController _controller;
  DiagnosticsCollector? _diagnostics;

  /// This exercise in today's plan, or null for free practice.
  PlanItem? _item;
  int _setNumber = 1;

  @override
  void initState() {
    super.initState();
    _exercise =
        ExerciseCatalog.byId(widget.exerciseId) ?? ExerciseCatalog.openClose;
    final overview = ref.read(programOverviewProvider).value;
    final settings = ref.read(programSettingsProvider);
    for (final i in overview?.plan?.items ?? const <PlanItem>[]) {
      if (i.exercise.id == _exercise.id) _item = i;
    }
    final item = _item;
    if (item != null) {
      _setNumber = (item.setsDone + 1).clamp(1, item.sets);
    }
    final ranges = ref.read(cameraSessionRangesProvider.notifier);
    if (kDebugMode && ref.read(diagnosticsEnabledProvider)) {
      _diagnostics = DiagnosticsCollector(log: true);
    }
    _controller = CameraExerciseController(
      exercise: _exercise,
      diagnostics: _diagnostics,
      trackerFactory: ref.read(handTrackerFactoryProvider),
      permission: ref.read(cameraPermissionProvider),
      repository: ref.read(exerciseSessionRepositoryProvider),
      loadRange: () {
        final r = ref.read(cameraSessionRangesProvider);
        return _exercise.usesSpread ? r.spread : r.openness;
      },
      saveRange: _exercise.usesSpread ? ranges.setSpread : ranges.setOpenness,
      setSize: item?.setSize ?? _exercise.setSizeFor(settings.setSize),
      wallClock: ref.read(clockProvider),
      // A short vibration on each counted rep, so you can feel it count
      // without looking. TODO(audio): speak the count too.
      onRepCounted: (_) => HapticFeedback.mediumImpact(),
      level: item == null ? null : overview?.level,
      checkWrist: settings.wristCheck,
    );
    // Refresh the plan once the set is saved, so "next" is up to date.
    _controller.saved.then((_) {
      if (mounted) {
        ref.invalidate(programOverviewProvider);
        ref.invalidate(progressDataProvider);
        ref.invalidate(progressOverviewProvider);
      }
    });
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
    clearImmersive();
    _controller.dispose(); // stops the camera
    _diagnostics?.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.cameraExercises);

  /// End of today's practice: ask about pain, then back to the plan.
  void _finishForToday() => context.go(Routes.painCheck('after'));

  String get _setLabel => _item == null
      ? 'Free practice'
      : 'Set $_setNumber of ${_item!.sets} · ${_item!.setSize} ${_exercise.repUnit} each';

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
    // The whole flow uses the full screen: the instructions need the room
    // for all four steps, and the camera steps need it for the camera.
    setImmersive(true);
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
            Row(
              children: [
                IconBadge(exerciseIcon(_exercise.kind), size: 64, solid: true),
                const SizedBox(width: RohabSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_setLabel, style: t.labelMedium),
                      const SizedBox(height: RohabSpace.s8 / 2),
                      Text(_exercise.title, style: t.headlineMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (_exercise.target != null) ...[
              const SizedBox(height: RohabSpace.s16),
              Align(
                alignment: Alignment.centerLeft,
                child: InfoChip(_exercise.target!, icon: Icons.repeat),
              ),
            ],
            const SizedBox(height: RohabSpace.s16),
            RohabCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _exercise.steps.length; i++)
                    _NumberedStep(
                      number: i + 1,
                      text: _exercise.steps[i],
                      last: i == _exercise.steps.length - 1,
                    ),
                ],
              ),
            ),
            if (_exercise.object != null) ...[
              const SizedBox(height: RohabSpace.s16),
              Text('You need: ${_exercise.object}.', style: t.labelLarge),
            ],
            const SizedBox(height: RohabSpace.s16),
            Text(
              'Take your time. Stop if anything hurts.',
              style: t.labelMedium,
            ),
            const SizedBox(height: RohabSpace.s16),
            PhotoSlot(caption: '${_exercise.title}, right hand shown.'),
            const SizedBox(height: RohabSpace.s16),
          ],
        );

      case FlowStep.permission:
        return _Page(
          secondary: back,
          primary: _PrimaryAction(
            label: 'Allow camera',
            onPressed: c.allowCamera,
          ),
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
          primary: _PrimaryAction(
            label: 'Open settings',
            onPressed: c.openSettings,
          ),
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
            Text(
              c.errorMessage ?? 'The camera could not start.',
              style: t.bodyLarge,
            ),
          ],
        );

      case FlowStep.handCheck:
        return CameraPage(
          tracker: c.tracker,
          frame: c.frame,
          diagnostics: _diagnostics,
          stats: () => c.stats,
          action: cancel,
          children: [
            _Instruction(
              HandDistanceCheck.advice(c.distance) ??
                  'Hold your hand inside the frame.',
            ),
            if (c.needsHandHelp) ...[
              const SizedBox(height: RohabSpace.s8),
              Text(
                'We cannot see your hand yet. Move the phone back a little '
                'so your whole hand fits, face a light, and keep the '
                'camera still.',
                style: t.labelMedium?.copyWith(color: context.colors.text),
              ),
            ],
          ],
        );

      case FlowStep.calibrate:
        final high = c.calibratePhase == CalibratePhase.high;
        final text = _exercise.usesSpread
            ? (high
                  ? 'Spread your fingers as wide as you can.'
                  : 'Now bring your fingers together.')
            : (high
                  ? 'Open your hand as wide as you can.'
                  : 'Now make a fist.');
        return CameraPage(
          tracker: c.tracker,
          frame: c.frame,
          diagnostics: _diagnostics,
          stats: () => c.stats,
          action: cancel,
          overlay: _CountdownBadge(seconds: c.secondsLeft),
          children: [_Instruction(text)],
        );

      case FlowStep.calibrationFailed:
        return CameraPage(
          tracker: c.tracker,
          frame: c.frame,
          diagnostics: _diagnostics,
          stats: () => c.stats,
          action: Row(
            children: [
              Expanded(child: cancel),
              const SizedBox(width: RohabSpace.s8),
              Expanded(
                child: _PrimaryAction(
                  label: 'Try again',
                  onPressed: c.retryCalibration,
                ),
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
        return CameraPage(
          tracker: c.tracker,
          frame: c.frame,
          diagnostics: _diagnostics,
          stats: () => c.stats,
          action: _TextAction(label: 'End exercise', onPressed: c.endExercise),
          children: [_ExerciseReadout(controller: c, exercise: _exercise)],
        );

      case FlowStep.done:
        final s = c.summary!;
        final unit = s.reps == 1
            ? _exercise.repUnit.replaceAll(RegExp(r's$'), '')
            : _exercise.repUnit;
        final headline = s.completed
            ? 'Set complete. ${s.reps} $unit.'
            : 'Set ended. ${s.reps} $unit.';
        final overview = ref.watch(programOverviewProvider);
        final next = overview.value?.plan?.next;
        final restSeconds = ref.watch(programSettingsProvider).restSeconds;
        final Widget? primary;
        final Widget? secondary;
        if (_item == null) {
          primary = _PrimaryAction(label: 'Back to plan', onPressed: _back);
          secondary = null;
        } else if (overview.isLoading) {
          primary = const _PrimaryAction(label: 'Saving', onPressed: null);
          secondary = null;
        } else if (next == null) {
          primary = _PrimaryAction(
            label: 'Finish for today',
            onPressed: _finishForToday,
          );
          secondary = null;
        } else {
          final same = next.exercise.id == _exercise.id;
          primary = _PrimaryAction(
            label: same ? 'Next set' : 'Next: ${next.exercise.title}',
            onPressed: () => context.pushReplacement(
              Routes.cameraExercise(next.exercise.id),
            ),
          );
          secondary = _TextAction(
            label: 'Finish for today',
            onPressed: _finishForToday,
          );
        }
        return _Page(
          secondary: secondary,
          primary: primary,
          children: [
            Text(_setLabel, style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8),
            Semantics(
              liveRegion: true,
              child: Text(headline, style: t.headlineMedium),
            ),
            if (s.reps == 0) ...[
              const SizedBox(height: RohabSpace.s16),
              Text(
                'Nothing was counted, so nothing was saved. '
                '${_zeroRepAdvice(_exercise)}',
                style: t.bodyLarge,
              ),
            ],
            // Resting only makes sense after a set that counted something.
            if (_item != null && next != null && s.reps > 0) ...[
              const SizedBox(height: RohabSpace.s16),
              _RestCountdown(seconds: restSeconds),
            ],
            if (s.compensatedReps > 0) ...[
              const SizedBox(height: RohabSpace.s16),
              Text(
                '${s.compensatedReps} did not count because the wrist '
                'moved. Keep your forearm resting and your wrist still.',
                style: t.bodyLarge,
              ),
            ],
            if (s.fatigued) ...[
              const SizedBox(height: RohabSpace.s16),
              Text(
                'Your later movements were smaller. '
                'Rest before the next set.',
                style: t.bodyLarge,
              ),
            ],
            const SizedBox(height: RohabSpace.s16),
            if (s.reps > 0 && s.rangeMin != null && s.rangeMax != null) ...[
              if (s.inDegrees) ...[
                Text(
                  'Range of motion: '
                  '${(s.rangeMax! - s.rangeMin!).round()}°',
                  style: t.bodyLarge,
                ),
                const SizedBox(height: RohabSpace.s8),
                Text(
                  'From ${s.rangeMin!.round()}° (open) to '
                  '${s.rangeMax!.round()}° (closed). Straight is 0°, a fist '
                  'is about 250°.',
                  style: t.labelMedium?.copyWith(color: context.colors.text),
                ),
              ] else
                Text(
                  'Range: ${s.rangeMin!.round()}%–${s.rangeMax!.round()}%',
                  style: t.bodyLarge,
                ),
            ],
            if (s.reps > 0 && s.inDegrees && s.rangeMin != null) ...[
              const SizedBox(height: RohabSpace.s16),
              Text(
                'Camera measurements are approximate and can be off by '
                '10° or more.',
                style: t.labelMedium,
              ),
            ],
          ],
        );
    }
  }
}

/// Rest between sets: counts down, then says it's time. Starting early is
/// allowed.
class _RestCountdown extends StatefulWidget {
  const _RestCountdown({required this.seconds});

  final int seconds;

  @override
  State<_RestCountdown> createState() => _RestCountdownState();
}

class _RestCountdownState extends State<_RestCountdown> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left = (_left - 1).clamp(0, widget.seconds));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Text(
        _left > 0 ? 'Rest for $_left s.' : 'Rested. Start when you are ready.',
        style: t.labelLarge,
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(
              RohabSpace.s24,
              RohabSpace.s16,
              RohabSpace.s24,
              0,
            ),
            children: children,
          ),
        ),
        ActionArea(secondary: secondary, primary: primary),
      ],
    );
  }
}

class _ExerciseReadout extends StatelessWidget {
  const _ExerciseReadout({required this.controller, required this.exercise});

  final CameraExerciseController controller;
  final CameraExercise exercise;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = controller;
    final colors = context.colors;
    // What the instruction line says, most important first.
    final String message = c.handLost
        ? 'Hold your hand inside the frame.'
        : c.wristCue
        ? 'Wrist moved. That one did not count.'
        : c.distance != HandDistance.good
        ? HandDistanceCheck.advice(c.distance)!
        : c.stuck
        ? 'Not counting? Make the movement bigger and slower, with '
              'your whole hand in view.'
        : c.suggestRest
        ? 'Movements are getting smaller. A rest may help.'
        : c.hint ?? 'Keep going.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: '${c.reps} of ${c.setSize} ${exercise.repUnit}',
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
                Text(
                  '${c.reps} of ${c.setSize}',
                  key: CameraExerciseFlow.repsKey,
                  style: t.displayLarge,
                ),
                const SizedBox(width: RohabSpace.s8),
                Text(exercise.repUnit, style: t.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: RohabSpace.s16),
        // One clear instruction, then the bar that shows how close the move
        // is. Same height whatever is shown, so the layout never jumps.
        SizedBox(
          height: RohabType.body * 1.25 * 2 + RohabSpace.s8 + 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.labelLarge?.copyWith(
                  color:
                      c.handLost ||
                          c.wristCue ||
                          c.stuck ||
                          c.distance != HandDistance.good
                      ? colors.text
                      : colors.accent,
                ),
              ),
              const SizedBox(height: RohabSpace.s8),
              if (!c.handLost)
                LevelBar(
                  value: c.meter,
                  semanticsLabel: 'Progress of this move',
                  semanticsValue: '${(c.meter * 100).round()} percent',
                  markers: [LevelMarker(c.meterMarker, 'Goal')],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({
    required this.number,
    required this.text,
    this.last = false,
  });

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : RohabSpace.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RaisedTile(
            size: RohabSpace.s32 + 4,
            color: c.accent,
            child: Text(
              '$number',
              style: t.labelMedium?.copyWith(
                color: c.onAccent,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(color: Color(0x66000000), offset: Offset(0, -1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: RohabSpace.s16),
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
    child: Text(
      text,
      key: CameraExerciseFlow.instructionKey,
      style: Theme.of(context).textTheme.titleLarge,
    ),
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

/// Big countdown on the camera, so it is never pushed off screen.
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: paperDecoration(context.colors, radius: RohabShape.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RohabSpace.s16,
          vertical: RohabSpace.s8,
        ),
        child: CountdownNumber(seconds: seconds),
      ),
    );
  }
}

/// What to try when a set counted nothing.
String _zeroRepAdvice(CameraExercise e) {
  const common = 'Keep your whole hand inside the camera view, in good light.';
  return switch (e.kind) {
    ExerciseKind.fingerTouches =>
      'Press the tip of your thumb to the tip of each finger, index first, '
          'one after another. $common',
    ExerciseKind.fingerLifts =>
      'Straighten one finger at a time while the others stay bent, index '
          'first. $common',
    ExerciseKind.holdOpen ||
    ExerciseKind.cylinder ||
    ExerciseKind.hook ||
    ExerciseKind.squeeze ||
    ExerciseKind.thumbExtension ||
    ExerciseKind.assistedExtension =>
      'Hold the position until the screen says to let go. $common',
    ExerciseKind.wristStretch =>
      'Keep your forearm still and bend only your wrist, then back to '
          'straight. $common',
    ExerciseKind.wristRotation =>
      'Turn your palm all the way over, then all the way back. $common',
    ExerciseKind.handSlide =>
      'Slide your hand a hand-width forward, then back to where it '
          'started. $common',
    ExerciseKind.flatFingerLifts || ExerciseKind.fingerWalking =>
      'Lift one finger clearly off the table at a time, index first, '
          'and lower it before the next. $common',
    _ => 'Open and close slowly and fully. $common',
  };
}
