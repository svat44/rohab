import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../glove/glove_service.dart';
import '../theme/app_theme.dart';

/// Connect to the glove, start and end a session, and follow it: reps
/// first, then what the hand is doing, then pressure as a detail.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const primaryButtonKey = Key('home-primary');
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
                children: [
                  const SizedBox(height: RohabSpace.s8),
                  if (s.faults.isNotEmpty) _FaultNotice(faults: s.faults),
                  if (calibrationNeeded) ...[
                    _CalibrationNeededRow(
                      onCalibrate: () => context.go(Routes.calibration),
                    ),
                    const Divider(),
                    const SizedBox(height: RohabSpace.s16),
                  ],
                  // Only after a session ends; cleared when the next starts.
                  if (_summary != null && !s.sessionActive) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(_summary!,
                          key: HomeScreen.summaryKey,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    const SizedBox(height: RohabSpace.s24),
                  ],
                  _RepsReadout(
                    reps: s.sessionActive || _summary != null
                        ? s.reps - _repsAtStart
                        : null,
                  ),
                  const SizedBox(height: RohabSpace.s16),
                  _HandState(snapshot: s),
                  const SizedBox(height: RohabSpace.s24),
                  const Divider(),
                  _PressureRow(snapshot: s),
                  const Divider(),
                  const SizedBox(height: RohabSpace.s24),
                ],
              ),
            ),
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
                  ? t.displayLarge
                      ?.copyWith(color: c.secondary, fontWeight: FontWeight.w400)
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
      child: Text(text,
          key: HomeScreen.stateKey,
          style: s.isConnected
              ? t.headlineMedium
              : t.bodyLarge?.copyWith(color: context.colors.secondary)),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
        child: Row(
          children: [
            Expanded(child: Text('Pressure', style: t.bodyLarge)),
            Text(
              s.isConnected ? s.pressureKpa.toStringAsFixed(1) : '–',
              key: HomeScreen.pressureKey,
              style: t.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(' of ${s.targetKpa.toStringAsFixed(0)} kPa',
                style: t.bodyLarge?.copyWith(color: c.secondary)),
          ],
        ),
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
    return ConstrainedBox(
      key: HomeScreen.calibrationNeededKey,
      constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
      child: Row(
        children: [
          Expanded(child: Text('Calibration needed', style: t.bodyLarge)),
          TextButton(onPressed: onCalibrate, child: const Text('Calibrate')),
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
      decoration: BoxDecoration(
        border: Border.all(color: c.danger),
        borderRadius: BorderRadius.circular(RohabShape.radius),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, RohabSpace.s16),
      child: FilledButton(
        key: HomeScreen.primaryButtonKey,
        onPressed: action,
        child: Text(label),
      ),
    );
  }
}
