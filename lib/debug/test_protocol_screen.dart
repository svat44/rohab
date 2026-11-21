import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/router.dart';
import '../data/database.dart';
import '../data/exercise_session_repository.dart';
import '../exercises/camera_exercise_controller.dart';
import '../exercises/exercise_catalog.dart';
import '../exercises/exercise_providers.dart';
import '../screens/exercises/camera_layout.dart';
import '../theme/app_theme.dart';
import '../widgets/action_area.dart';
import '../widgets/immersive.dart';
import 'diagnostics.dart';
import 'protocol_report.dart';

/// Length of the counting run for each pose.
const Duration kProtocolRun = Duration(seconds: 30);

/// Saves nothing: the protocol is a measurement, not an exercise.
class _NullSessionRepository extends ExerciseSessionRepository {
  @override
  Future<int> save(ExerciseSessionRecord record) async => 0;

  @override
  Future<List<ExerciseSessionRow>> all() async => const [];

  @override
  Future<void> deleteAll() async {}
}

/// Debug builds only. Runs the real exercise flow (hand check, range
/// calibration, counting) for 30 s per pose, and prints a summary table.
/// Records numbers only. Never landmarks, images or video.
class TestProtocolScreen extends ConsumerStatefulWidget {
  const TestProtocolScreen({super.key});

  static const startKey = Key('protocol-start');
  static const tableKey = Key('protocol-table');

  @override
  ConsumerState<TestProtocolScreen> createState() => _TestProtocolScreenState();
}

enum _Phase { intro, running, summary }

class _TestProtocolScreenState extends ConsumerState<TestProtocolScreen>
    with ImmersiveScreen<TestProtocolScreen> {
  _Phase _phase = _Phase.intro;
  int _pose = 0;
  final List<PoseResult> _results = [];

  CameraExerciseController? _c;
  DiagnosticsCollector? _diag;
  Timer? _timer;
  DiagnosticsSnapshot? _runStart;
  Duration _runStartNow = Duration.zero;
  bool _finishing = false;

  @override
  void dispose() {
    _timer?.cancel();
    clearImmersive();
    _c?.dispose();
    _diag?.dispose();
    super.dispose();
  }

  void _startPose() {
    final diag = DiagnosticsCollector(log: true);
    final c = CameraExerciseController(
      exercise: ExerciseCatalog.openClose,
      trackerFactory: ref.read(handTrackerFactoryProvider),
      permission: ref.read(cameraPermissionProvider),
      repository: _NullSessionRepository(),
      loadRange: () => null, // always calibrate, as a new session does
      saveRange: (_) {},
      setSize: 9999, // never completes by itself
      diagnostics: diag,
    );
    _runStart = null;
    _finishing = false;
    setState(() {
      _diag = diag;
      _c = c;
      _phase = _Phase.running;
    });
    c.addListener(() => mounted ? setState(() {}) : null);
    c.start();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _check());
  }

  void _check() {
    final c = _c, diag = _diag;
    if (c == null || diag == null || _finishing) return;
    const failed = {
      FlowStep.cameraError,
      FlowStep.permissionDenied,
      FlowStep.permission,
      FlowStep.calibrationFailed,
    };
    if (failed.contains(c.step)) {
      _finish(note: c.step == FlowStep.calibrationFailed
          ? 'range too small to calibrate'
          : 'camera: ${c.step.name}');
      return;
    }
    if (c.step != FlowStep.exercise) return;
    if (_runStart == null) {
      _runStart = diag.snapshot(c.now);
      _runStartNow = c.now;
      return;
    }
    if (c.now - _runStartNow >= kProtocolRun) _finish();
  }

  Future<void> _finish({String? note}) async {
    final c = _c, diag = _diag;
    if (c == null || diag == null || _finishing) return;
    _finishing = true;
    _timer?.cancel();
    final spec = PoseSpec.all[_pose];
    final reps = c.reps;
    PoseResult result;
    if (note != null || _runStart == null) {
      result = PoseResult(
          pose: spec, seconds: 0, avgFps: 0, detectionPercent: 0,
          dropouts: 0, reps: 0, note: note ?? 'did not reach counting');
    } else {
      final s = RunSummary.between(_runStart!, diag.snapshot(c.now));
      result = PoseResult(
        pose: spec,
        seconds: s.seconds,
        avgFps: s.avgFps,
        detectionPercent: s.detectionPercent,
        dropouts: s.dropouts,
        reps: reps,
      );
    }
    await c.endExercise();
    c.dispose();
    diag.dispose();
    _c = null;
    _diag = null;
    _results.add(result);
    debugPrint('[protocol] ${spec.title}\n${formatProtocolTable(_results)}');
    if (!mounted) return;
    setState(() {
      _pose++;
      _phase = _pose >= PoseSpec.all.length ? _Phase.summary : _Phase.intro;
    });
  }

  @override
  Widget build(BuildContext context) {
    setImmersive(_phase == _Phase.running);
    final t = Theme.of(context).textTheme;
    switch (_phase) {
      case _Phase.intro:
        final spec = PoseSpec.all[_pose];
        return _Page(
          secondary: TextButton(
            onPressed: () => context.go(Routes.exercises),
            child: const Text('Leave'),
          ),
          primary: FilledButton(
            key: TestProtocolScreen.startKey,
            onPressed: _startPose,
            child: Text('Start pose ${_pose + 1} of ${PoseSpec.all.length}'),
          ),
          children: [
            Text('Test protocol (debug)', style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8),
            Text(spec.title, style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(spec.instruction, style: t.bodyLarge),
            const SizedBox(height: RohabSpace.s16),
            Text(
              'Each run: a hand check, a 6 s range calibration (open wide, '
              'then fist, at this pose\'s limits), then '
              '${kProtocolRun.inSeconds} s of counting. Prop the phone '
              'upright and keep the whole hand in view.',
              style: t.labelMedium?.copyWith(color: context.colors.text),
            ),
          ],
        );
      case _Phase.running:
        final c = _c!;
        final left = _runStart == null
            ? null
            : (kProtocolRun - (c.now - _runStartNow)).inSeconds.clamp(0, 999);
        final text = switch (c.step) {
          FlowStep.exercise => 'Keep going. ${left ?? kProtocolRun.inSeconds} s '
              'left. Reps: ${c.reps}',
          FlowStep.calibrate => c.calibratePhase == CalibratePhase.high
              ? 'Open as wide as this pose allows.'
              : 'Now close as far as this pose allows.',
          _ => 'Hold your hand inside the frame.',
        };
        return CameraPage(
          tracker: c.tracker,
          frame: c.frame,
          diagnostics: _diag,
          stats: () => c.stats,
          action: TextButton(
              onPressed: () => _finish(note: 'stopped'),
              child: const Text('Stop this pose')),
          children: [
            Text(PoseSpec.all[_pose].title, style: t.labelMedium),
            Text(text, style: t.titleLarge),
          ],
        );
      case _Phase.summary:
        final table = formatProtocolTable(_results);
        return _Page(
          primary: FilledButton(
            onPressed: () => context.go(Routes.exercises),
            child: const Text('Done'),
          ),
          children: [
            Text('Test protocol results', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s8),
            Text('Also printed to the console.', style: t.labelMedium),
            const SizedBox(height: RohabSpace.s16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                table,
                key: TestProtocolScreen.tableKey,
                style: t.labelMedium?.copyWith(
                    fontFamily: 'monospace', color: context.colors.text),
              ),
            ),
          ],
        );
    }
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children, this.primary, this.secondary});

  final List<Widget> children;
  final Widget? primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, 0),
              children: children,
            ),
          ),
          ActionArea(secondary: secondary, primary: primary),
        ],
      );
}
