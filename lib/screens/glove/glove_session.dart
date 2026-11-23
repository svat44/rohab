import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/level_bar.dart';
import '../../widgets/rohab_button.dart';
import '../../widgets/rohab_row.dart';

/// The glove session on the Glove tab: connect, start, end, and follow it.
/// Glove-only numbers (reps, pressure) show only while a glove is connected;
/// with no glove there are no dashes in their place.
class GloveSession extends ConsumerStatefulWidget {
  const GloveSession({super.key});

  static const primaryButtonKey = Key('glove-primary');
  static const pressureKey = Key('glove-pressure');
  static const repsKey = Key('glove-reps');
  static const stateKey = Key('glove-state');
  static const summaryKey = Key('glove-summary');
  static const statusKey = Key('glove-status');

  @override
  ConsumerState<GloveSession> createState() => _GloveSessionState();
}

class _GloveSessionState extends ConsumerState<GloveSession> {
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
      if (mounted) {
        setState(() {
          _summary = s.faults.isNotEmpty
              ? null
              : _endRequested
              ? 'Session complete. $reps $repWord.'
              : 'Session stopped. $reps $repWord.';
        });
      }
      _endRequested = false;
    }
    _wasActive = s.sessionActive;
  }

  @override
  Widget build(BuildContext context) {
    final glove = ref.watch(gloveServiceProvider);
    final c = context.colors;
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        final (label, action) = switch (s.connection) {
          GloveConnection.disconnected => ('Connect glove', glove.connect),
          GloveConnection.connecting => ('Connecting', null),
          GloveConnection.connected when s.sessionActive => (
            'End session',
            () {
              _endRequested = true;
              glove.stop();
            },
          ),
          GloveConnection.connected => (
            'Start session',
            () {
              setState(() {
                _summary = null;
                _repsAtStart = s.reps;
              });
              glove.start();
            },
          ),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.faults.isNotEmpty)
              Container(
                color: c.surface,
                padding: const EdgeInsets.all(RohabSpace.gutter),
                margin: const EdgeInsets.only(bottom: RohabSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.faults.map((f) => f.label).join('. '),
                      style: RohabType.rowTitle.copyWith(color: c.danger),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The glove has vented. Check the fit, then start again.',
                      style: RohabType.body,
                    ),
                  ],
                ),
              ),
            if (_summary != null && !s.sessionActive)
              Padding(
                padding: const EdgeInsets.all(RohabSpace.gutter),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _summary!,
                    key: GloveSession.summaryKey,
                    style: RohabType.rowTitle,
                  ),
                ),
              ),
            if (s.isConnected) ...[
              RohabGroup(
                children: [
                  RohabRow(
                    valueKey: GloveSession.repsKey,
                    valueStyle: RohabType.metricL,
                    title: 'Reps this session',
                    value: s.sessionActive || _summary != null
                        ? '${s.reps - _repsAtStart}'
                        : 'No session yet',
                  ),
                  RohabRow(
                    valueKey: GloveSession.stateKey,
                    title: 'Hand',
                    value: s.state.patientLabel,
                  ),
                  Container(
                    color: c.surface,
                    padding: const EdgeInsets.all(RohabSpace.gutter),
                    child: _Pressure(snapshot: s),
                  ),
                ],
              ),
              const SizedBox(height: RohabSpace.s16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RohabSpace.gutter,
              ),
              child: RohabButton(
                key: GloveSession.primaryButtonKey,
                label: label,
                onPressed: action,
                kind:
                    s.connection == GloveConnection.connected &&
                        !s.sessionActive
                    ? RohabButtonKind.primary
                    : RohabButtonKind.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Pressure extends StatelessWidget {
  const _Pressure({required this.snapshot});

  final GloveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Semantics(
      label:
          'Pressure ${s.pressureKpa.toStringAsFixed(0)} of '
          '${s.targetKpa.toStringAsFixed(0)} kilopascals',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: RohabSpace.s8,
            children: [
              const Text('Pressure', style: RohabType.rowTitle),
              Text(
                s.pressureKpa.toStringAsFixed(1),
                key: GloveSession.pressureKey,
                style: RohabType.metricS.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'of ${s.targetKpa.toStringAsFixed(0)} kPa',
                style: RohabType.metricS.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RohabSpace.s8),
          LevelBar(
            value: s.targetKpa > 0 ? s.pressureKpa / s.targetKpa : 0,
            semanticsLabel: 'Pressure',
            semanticsValue: '${s.pressureKpa.toStringAsFixed(0)} kilopascals',
          ),
        ],
      ),
    );
  }
}
