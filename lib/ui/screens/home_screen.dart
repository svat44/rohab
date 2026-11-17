import 'package:material_ui/material_ui.dart';

import '../../app/glove_scope.dart';
import '../../glove/glove_service.dart';
import '../theme.dart';

/// Connect to the glove, watch live pressure, start and end a session.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const title = 'Home';
  static const primaryButtonKey = Key('home-primary');
  static const pressureKey = Key('home-pressure');

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GloveService? _glove;
  bool _wasActive = false;
  bool _endRequested = false;
  int _repsAtStart = 0;
  String? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final glove = GloveScope.of(context);
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
    final glove = GloveScope.of(context);
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                children: [
                  const SizedBox(height: Space.s1),
                  // Outcome first: it's what the user looks for after a stop.
                  if (s.faults.isNotEmpty) _FaultNotice(faults: s.faults),
                  if (_summary != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.s3),
                      child: Text(
                        _summary!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  _PressureReadout(snapshot: s),
                  const SizedBox(height: Space.s4),
                  const Divider(),
                  _Row(
                    label: 'Glove',
                    value: s.isConnected ? s.state.label : '–',
                  ),
                  const Divider(),
                  _Row(
                    label: 'Reps this session',
                    value: s.sessionActive || _summary != null
                        ? '${s.reps - _repsAtStart}'
                        : '–',
                  ),
                  const Divider(),
                  _Row(label: 'Mode', value: s.mode.label),
                  const Divider(),
                  const SizedBox(height: Space.s3),
                ],
              ),
            ),
            _Actions(
              snapshot: s,
              onConnect: glove.connect,
              onDisconnect: glove.disconnect,
              onStart: () => _start(s),
              onEnd: _end,
            ),
          ],
        );
      },
    );
  }
}

class _PressureReadout extends StatelessWidget {
  const _PressureReadout({required this.snapshot});

  final GloveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final s = snapshot;
    final value = s.isConnected ? s.pressureKpa.toStringAsFixed(1) : '–';

    return Semantics(
      label: s.isConnected
          ? 'Pressure ${s.pressureKpa.toStringAsFixed(0)} kilopascals'
          : 'Pressure unavailable, glove not connected',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pressure', style: t.labelMedium),
          const SizedBox(height: Space.s1),
          // Scales down instead of overflowing at large system text sizes.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  key: HomeScreen.pressureKey,
                  style: s.isConnected
                      ? t.displayLarge
                      : t.displayLarge?.copyWith(
                          color: c.gray, fontWeight: FontWeight.w400),
                ),
                const SizedBox(width: Space.s1),
                Text('kPa',
                    style:
                        t.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: Space.s1),
          Text(
            'Target ${s.targetKpa.toStringAsFixed(0)} kPa',
            style: t.bodyLarge?.copyWith(color: c.gray),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyLarge)),
          const SizedBox(width: Space.s2),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.55),
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
      margin: const EdgeInsets.only(bottom: Space.s3),
      padding: const EdgeInsets.all(Space.s2),
      decoration: BoxDecoration(
        border: Border.all(color: c.danger),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faults.map((f) => f.label).join('. '),
            style: t.titleMedium?.copyWith(color: c.danger),
          ),
          const SizedBox(height: Space.s1),
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
    required this.onDisconnect,
    required this.onStart,
    required this.onEnd,
  });

  final GloveSnapshot snapshot;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
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
    final canDisconnect = s.isConnected && !s.sessionActive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.s3, Space.s2, Space.s3, Space.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // The primary button never moves: the secondary slot above it is
        // always reserved, so a repeat tap in the same place can't land on
        // a different action.
        children: [
          SizedBox(
            height: Sizes.touchTarget,
            child: canDisconnect
                ? TextButton(
                    onPressed: onDisconnect, child: const Text('Disconnect'))
                : null,
          ),
          const SizedBox(height: Space.s1),
          FilledButton(
            key: HomeScreen.primaryButtonKey,
            onPressed: action,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
