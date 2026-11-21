import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../camera/handedness.dart';
import '../../exercises/exercise_providers.dart';
import '../../program/baseline.dart';
import '../../program/baseline_controller.dart';
import '../../program/program_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_area.dart';
import '../../widgets/countdown_number.dart';
import '../../widgets/immersive.dart';
import 'camera_layout.dart';
import 'program_screen.dart';

/// Measures both hands and sets the starting level.
class BaselineScreen extends ConsumerStatefulWidget {
  const BaselineScreen({super.key});

  static const leftKey = Key('baseline-left');
  static const rightKey = Key('baseline-right');
  static const primaryKey = Key('baseline-primary');
  static const secondaryKey = Key('baseline-secondary');
  static const instructionKey = Key('baseline-instruction');

  @override
  ConsumerState<BaselineScreen> createState() => _BaselineScreenState();
}

class _BaselineScreenState extends ConsumerState<BaselineScreen>
    with WidgetsBindingObserver, ImmersiveScreen<BaselineScreen> {
  late final BaselineController _c;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(programRepositoryProvider);
    _c = BaselineController(
      trackerFactory: ref.read(handTrackerFactoryProvider),
      permission: ref.read(cameraPermissionProvider),
      wallClock: ref.read(clockProvider),
      save: (r) async {
        await repo.saveBaseline(r);
        if (mounted) ref.invalidate(programOverviewProvider);
      },
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c.recheckPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    clearImmersive();
    _c.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.cameraExercises);

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _c, builder: (context, _) => _step(context));

  Widget _step(BuildContext context) {
    final t = Theme.of(context).textTheme;
    setImmersive(true);
    final back = TextButton(
        key: BaselineScreen.secondaryKey, onPressed: _back, child: const Text('Back'));
    String hand(Handedness h) => BaselineController.handName(h);

    switch (_c.step) {
      case BaselineStep.chooseHand:
        return _Page(
          secondary: back,
          children: [
            // The choices come right after the question, so they are on
            // screen even with large text.
            Text('Which hand did the stroke affect?', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s24),
            _Choice(
              key: BaselineScreen.leftKey,
              label: 'Left hand',
              onPressed: () => _c.chooseHand(Handedness.left),
            ),
            const SizedBox(height: RohabSpace.s16),
            _Choice(
              key: BaselineScreen.rightKey,
              label: 'Right hand',
              onPressed: () => _c.chooseHand(Handedness.right),
            ),
            const SizedBox(height: RohabSpace.s24),
            Text(
              'Rohab measures that hand first, then your other hand to '
              'compare. Rest your forearm on a table with the side of your '
              'hand facing the phone.',
              style: t.bodyLarge,
            ),
          ],
        );
      case BaselineStep.permission:
        return _Page(
          secondary: back,
          primary: FilledButton(
              key: BaselineScreen.primaryKey,
              onPressed: _c.allowCamera,
              child: const Text('Allow camera')),
          children: [
            Text('Camera', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(
                'Rohab uses the camera to measure your hand. Video stays on '
                'this phone and is never saved.',
                style: t.bodyLarge),
          ],
        );
      case BaselineStep.permissionDenied:
        return _Page(
          secondary: back,
          primary: FilledButton(
              key: BaselineScreen.primaryKey,
              onPressed: _c.openSettings,
              child: const Text('Open settings')),
          children: [
            Text('Camera is off for Rohab', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(
                'Turn on camera access for Rohab in Settings, then come back here.',
                style: t.bodyLarge),
          ],
        );
      case BaselineStep.starting:
        return _Page(
            secondary: back,
            children: [Text('Starting the camera.', style: t.bodyLarge)]);
      case BaselineStep.cameraError:
      case BaselineStep.failed:
        return _Page(
          secondary: back,
          primary: FilledButton(
              key: BaselineScreen.primaryKey,
              onPressed: _c.retry,
              child: const Text('Try again')),
          children: [
            Text(_c.errorMessage ?? 'The camera could not start.',
                style: t.bodyLarge),
          ],
        );
      case BaselineStep.handCheck:
        return CameraPage(
          tracker: _c.tracker,
          frame: _c.frame,
          stats: () => _c.stats,
          action: TextButton(
              key: BaselineScreen.secondaryKey,
              onPressed: _back,
              child: const Text('Cancel')),
          children: [
            Text('${_c.measuringOther ? 'Other hand' : 'Affected hand'}: ${hand(_c.currentHand)}',
                style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8),
            Text('Hold your ${hand(_c.currentHand)} hand inside the frame.',
                key: BaselineScreen.instructionKey, style: t.titleLarge),
            if (_c.handHint != null) ...[
              const SizedBox(height: RohabSpace.s8),
              Text(_c.handHint!, style: t.labelLarge),
            ],
          ],
        );
      case BaselineStep.measure:
        final open = _c.phase == MeasurePhase.open;
        return CameraPage(
          tracker: _c.tracker,
          frame: _c.frame,
          stats: () => _c.stats,
          overlay: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(RohabShape.radius),
              border: Border.all(
                  color: context.colors.divider, width: RohabShape.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: RohabSpace.s16, vertical: RohabSpace.s8),
              child: CountdownNumber(seconds: _c.secondsLeft),
            ),
          ),
          action: TextButton(
              key: BaselineScreen.secondaryKey,
              onPressed: _back,
              child: const Text('Cancel')),
          children: [
            Text(
                '${_c.measuringOther ? 'Other hand' : 'Affected hand'} · '
                '${_c.cycle} of ${BaselineController.cycles}',
                style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8),
            Semantics(
              liveRegion: true,
              child: Text(
                open
                    ? 'Open your hand as far as you can.'
                    : 'Now close it as far as you can.',
                key: BaselineScreen.instructionKey,
                style: t.titleLarge,
              ),
            ),
            if (_c.handHint != null) ...[
              const SizedBox(height: RohabSpace.s8),
              Text(_c.handHint!, style: t.labelLarge),
            ],
          ],
        );
      case BaselineStep.otherHandPrompt:
        return _Page(
          secondary: TextButton(
              key: BaselineScreen.secondaryKey,
              onPressed: _c.skipOther,
              child: const Text('Skip')),
          primary: FilledButton(
              key: BaselineScreen.primaryKey,
              onPressed: _c.measureOther,
              child: const Text('Measure other hand')),
          children: [
            Text('Now your ${hand(_c.currentHand == Handedness.left ? Handedness.right : Handedness.left)} hand',
                style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s16),
            Text(
              'Your other hand shows what is normal for you. If both hands '
              'were affected, skip this.',
              style: t.bodyLarge,
            ),
          ],
        );
      case BaselineStep.result:
        final r = _c.result!;
        return _Page(
          primary: FilledButton(
            key: BaselineScreen.primaryKey,
            onPressed: _back,
            child: const Text("See today's plan"),
          ),
          children: [
            Text('Starting level: ${r.level}', style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s8),
            Text(ProgramScreen.levelNames[r.level]!, style: t.bodyLarge),
            const SizedBox(height: RohabSpace.s24),
            const Divider(),
            _RangeRow(label: '${_cap(hand(r.affectedHand))} hand (affected)', range: r.affected),
            const Divider(),
            if (r.other != null) ...[
              _RangeRow(
                  label: '${_cap(hand(r.affectedHand == Handedness.left ? Handedness.right : Handedness.left))} hand',
                  range: r.other!),
              const Divider(),
            ],
            const SizedBox(height: RohabSpace.s16),
            if (r.rangeRatio != null)
              Text(
                'Your affected hand moves ${(r.rangeRatio! * 100).round()}% '
                'as far as your other hand.',
                style: t.bodyLarge,
              ),
            if (r.cameraLimited) ...[
              const SizedBox(height: RohabSpace.s16),
              Text(
                'Your movement is smaller than the camera can count '
                'reliably. Practice with your therapist or the glove as well.',
                style: t.bodyLarge,
              ),
            ],
            const SizedBox(height: RohabSpace.s16),
            Text(
              'Range is the total bend of your finger joints, from most open '
              'to most closed. Camera numbers are approximate and can be off '
              'by 10° or more. Rohab will ask you to measure again in a week.',
              style: t.labelMedium,
            ),
          ],
        );
    }
  }

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.label, required this.range});

  final String label;
  final HandRange range;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RohabSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: t.bodyLarge)),
              Text('${range.range.round()}°', style: t.labelLarge),
            ],
          ),
          const SizedBox(height: RohabSpace.s8 / 2),
          Text(
            'Bend from ${range.open.round()}° (most open) to '
            '${range.closed.round()}° (most closed)',
            style: t.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: RohabSize.touchTarget,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.colors.text,
            side: BorderSide(color: context.colors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RohabShape.radius)),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: Text(label),
        ),
      );
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
