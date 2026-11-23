import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../glove/glove_service.dart';
import '../program/program_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/skeuo.dart';
import '../widgets/level_bar.dart';
import '../widgets/rohab_widgets.dart';

/// Connect to the glove, start and end a session, and follow it: reps
/// first, then what the hand is doing, then pressure as a detail.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const primaryButtonKey = Key('home-primary');
  static const todayKey = Key('home-today');
  static const todayPrimaryKey = Key('home-today-primary');
  static const pressureKey = Key('home-pressure');
  static const repsKey = Key('home-reps');
  static const stateKey = Key('home-state');
  static const summaryKey = Key('home-summary');
  static const calibrationNeededKey = Key('home-calibration-needed');

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GloveService? _glove;
  bool _wasActive = false;
  bool _endRequested = false;
  int _repsAtStart = 0;
  String? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final glove = ref.read(gloveServiceProvider);
    if (glove != _glove) {
      _glove?.snapshot.removeListener(_onSnapshot);
      _glove = glove..snapshot.addListener(_onSnapshot);
      _wasActive = glove.snapshot.value.sessionActive;
    }
  }

  @override
  void dispose() {
    _glove?.snapshot.removeListener(_onSnapshot);
    super.dispose();
  }

  void _onSnapshot() {
    final s = _glove!.snapshot.value;
    if (_wasActive && !s.sessionActive) {
      final reps = s.reps - _repsAtStart;
      final repWord = reps == 1 ? 'rep' : 'reps';
      setState(() {
        _summary = s.faults.isNotEmpty
            ? null
            : _endRequested
            ? 'Session complete. $reps $repWord.'
            : 'Session stopped. $reps $repWord.';
      });
      _endRequested = false;
    }
    _wasActive = s.sessionActive;
  }

  void _start(GloveSnapshot s) {
    setState(() {
      _summary = null;
      _repsAtStart = s.reps;
    });
    _glove!.start();
  }

  void _end() {
    _endRequested = true;
    _glove!.stop();
  }

  @override
  Widget build(BuildContext context) {
    final glove = ref.watch(gloveServiceProvider);
    final calibrationNeeded = ref.watch(calibrationNeededProvider);
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        return ListView(
          // A short list: build every card, so none is missing when
          // large text pushes it below the fold.
          scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
          padding: const EdgeInsets.fromLTRB(
            RohabSpace.s24,
            RohabSpace.s8,
            RohabSpace.s24,
            RohabSpace.s24,
          ),
          children: [
            const _TodayCard(),
            const SectionTitle(
              'Glove',
              subtitle: 'Only if you use the Rohab glove.',
            ),
            if (s.faults.isNotEmpty) _FaultNotice(faults: s.faults),
            if (calibrationNeeded) ...[
              _CalibrationNeededRow(
                onCalibrate: () => context.go(Routes.calibration),
              ),
              const SizedBox(height: RohabSpace.s16),
            ],
            // Only after a session ends; cleared when the next starts.
            if (_summary != null && !s.sessionActive) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _summary!,
                  key: HomeScreen.summaryKey,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: RohabSpace.s24),
            ],
            // Glove numbers appear only with a glove: no dashes in place of
            // numbers. The STOP banner is separate and unaffected.
            if (!s.isConnected)
              RohabCard(
                child: Text(
                  'Glove not connected. Glove exercises are off.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else ...[
            RohabCard(
              padding: const EdgeInsets.all(RohabSpace.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RepsReadout(
                    reps: s.sessionActive || _summary != null
                        ? s.reps - _repsAtStart
                        : null,
                  ),
                  const SizedBox(height: RohabSpace.s16),
                  _HandState(snapshot: s),
                ],
              ),
            ),
            const SizedBox(height: RohabSpace.s16),
            RohabCard(child: _PressureRow(snapshot: s)),
            ],
            const SizedBox(height: RohabSpace.s16),
            _Actions(
              snapshot: s,
              onConnect: glove.connect,
              onStart: () => _start(s),
              onEnd: _end,
            ),
          ],
        );
      },
    );
  }
}

/// The one thing to do next: measure the hands, or do today's exercises.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final overview = ref.watch(programOverviewProvider).value;
    if (overview == null) return const SizedBox.shrink();
    final plan = overview.plan;

    if (plan == null) {
      return RohabCard(
        key: HomeScreen.todayKey,
        padding: const EdgeInsets.all(RohabSpace.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Start here', style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8),
            Text("Let's measure your hands", style: t.headlineMedium),
            const SizedBox(height: RohabSpace.s8),
            Text(
              'This takes about 2 minutes. It picks exercises that fit you.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: RohabSpace.s24),
            FilledButton(
              key: HomeScreen.todayPrimaryKey,
              onPressed: () => context.go(Routes.baseline),
              child: const Text('Measure my hands'),
            ),
          ],
        ),
      );
    }

    final next = plan.next;
    final done = plan.setsDoneTotal;
    final total = plan.setsTotal;
    final String label;
    final VoidCallback? action;
    if (next != null) {
      label = done == 0 ? 'Start' : 'Continue';
      action = () => context.go(
        overview.painBefore == null
            ? Routes.painCheck('before', next: next.exercise.id)
            : Routes.cameraExercise(next.exercise.id),
      );
    } else if (overview.painAfter == null && overview.painBefore != null) {
      label = 'Finish for today';
      action = () => context.go(Routes.painCheck('after'));
    } else {
      label = 'Done for today';
      action = null;
    }
    return RohabCard(
      key: HomeScreen.todayKey,
      padding: const EdgeInsets.all(RohabSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            next == null ? 'Well done' : "Today's exercises",
            style: t.headlineMedium,
          ),
          const SizedBox(height: RohabSpace.s8),
          Text(
            next == null
                ? 'You finished your exercises for today.'
                : 'Next: ${next.exercise.title}',
            style: t.bodyLarge,
          ),
          const SizedBox(height: RohabSpace.s16),
          Text('$done of $total sets done', style: t.labelLarge),
          const SizedBox(height: RohabSpace.s8),
          LevelBar(
            value: total == 0 ? 0 : done / total,
            semanticsLabel: 'Sets today',
            semanticsValue: '$done of $total',
          ),
          const SizedBox(height: RohabSpace.s24),
          FilledButton(
            key: HomeScreen.todayPrimaryKey,
            onPressed: action,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

/// Primary number: reps this session.
class _RepsReadout extends StatelessWidget {
  const _RepsReadout({required this.reps});

  /// Null before any session.
  final int? reps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Semantics(
      label: reps == null ? 'No session yet' : '$reps reps this session',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reps this session', style: t.labelMedium),
          const SizedBox(height: RohabSpace.s8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              reps == null ? '–' : '$reps',
              key: HomeScreen.repsKey,
              style: reps == null
                  ? t.displayLarge?.copyWith(
                      color: c.secondary,
                      fontWeight: FontWeight.w400,
                    )
                  : t.displayLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// Second: what the hand is doing, in plain words.
class _HandState extends StatelessWidget {
  const _HandState({required this.snapshot});

  final GloveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = snapshot;
    final text = switch (s.connection) {
      GloveConnection.connected => s.state.patientLabel,
      GloveConnection.connecting => 'Connecting',
      GloveConnection.disconnected => 'Connect the glove to start',
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        key: HomeScreen.stateKey,
        style: s.isConnected
            ? t.headlineMedium
            : t.bodyLarge?.copyWith(color: context.colors.secondary),
      ),
    );
  }
}

/// Detail: live pressure against the target.
class _PressureRow extends StatelessWidget {
  const _PressureRow({required this.snapshot});

  final GloveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final s = snapshot;
    return Semantics(
      label: s.isConnected
          ? 'Pressure ${s.pressureKpa.toStringAsFixed(0)} of '
                '${s.targetKpa.toStringAsFixed(0)} kilopascals'
          : 'Pressure unavailable',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(Icons.compress, size: 40),
              const SizedBox(width: RohabSpace.s16),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Pressure  ', style: t.bodyLarge),
                    Text(
                      s.isConnected ? s.pressureKpa.toStringAsFixed(1) : '–',
                      key: HomeScreen.pressureKey,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      ' of ${s.targetKpa.toStringAsFixed(0)} kPa',
                      style: t.bodyLarge?.copyWith(color: c.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RohabSpace.s16),
          LevelBar(
            value: s.isConnected && s.targetKpa > 0
                ? s.pressureKpa / s.targetKpa
                : 0,
            semanticsLabel: 'Pressure',
            semanticsValue: s.isConnected
                ? '${s.pressureKpa.toStringAsFixed(0)} kilopascals'
                : 'unavailable',
          ),
        ],
      ),
    );
  }
}

class _CalibrationNeededRow extends StatelessWidget {
  const _CalibrationNeededRow({required this.onCalibrate});

  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return RohabCard(
      key: HomeScreen.calibrationNeededKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(Icons.tune, size: 40),
              const SizedBox(width: RohabSpace.s16),
              Expanded(child: Text('Calibration needed', style: t.bodyLarge)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onCalibrate,
              child: const Text('Calibrate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaultNotice extends StatelessWidget {
  const _FaultNotice({required this.faults});

  final Set<GloveFault> faults;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: RohabSpace.s24),
      padding: const EdgeInsets.all(RohabSpace.s16),
      decoration: paperDecoration(c).copyWith(
        border: Border.all(color: c.danger, width: RohabShape.strongBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faults.map((f) => f.label).join('. '),
            style: t.labelLarge?.copyWith(color: c.danger),
          ),
          const SizedBox(height: RohabSpace.s8),
          Text(
            'The glove has vented. Check the fit, then start again.',
            style: t.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.snapshot,
    required this.onConnect,
    required this.onStart,
    required this.onEnd,
  });

  final GloveSnapshot snapshot;
  final VoidCallback onConnect;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final (label, action) = switch (s.connection) {
      GloveConnection.disconnected => ('Connect glove', onConnect),
      GloveConnection.connecting => ('Connecting…', null),
      GloveConnection.connected when s.sessionActive => ('End session', onEnd),
      GloveConnection.connected => ('Start session', onStart),
    };
    // One action, always in the same place. Disconnect is in Settings.
    return FilledButton(
      key: HomeScreen.primaryButtonKey,
      onPressed: action,
      child: Text(label),
    );
  }
}
