import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../onboarding/onboarding.dart';
import '../theme/app_theme.dart';
import '../widgets/action_area.dart';
import '../widgets/rohab_widgets.dart';

/// First-run guide: four short steps, one idea each, then straight into
/// measuring the hands. Big text, one main button, always a way back.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  static const nextKey = Key('welcome-next');
  static const backKey = Key('welcome-back');
  static const skipKey = Key('welcome-skip');

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _steps = 4;
  int _step = 0;

  Future<void> _finish(String route) async {
    await markOnboardingDone(ref.read(sharedPreferencesProvider));
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final last = _step == _steps - 1;

    final (title, body) = switch (_step) {
      0 => ('Welcome to Rohab', _welcome(context)),
      1 => ('How it works', _how(context)),
      2 => ('Before you start', _care(context)),
      _ => ('Set up your phone', _setup(context)),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, 0),
                  child: Semantics(
                    label: 'Step ${_step + 1} of $_steps',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        for (var i = 0; i < _steps; i++) ...[
                          if (i > 0) const SizedBox(width: RohabSpace.s8),
                          Expanded(
                            child: Container(
                              height: 8,
                              color: i <= _step ? c.accent : c.divider,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(RohabSpace.s24,
                        RohabSpace.s24, RohabSpace.s24, RohabSpace.s16),
                    children: [
                      Text('Step ${_step + 1} of $_steps',
                          style: t.labelMedium),
                      const SizedBox(height: RohabSpace.s8),
                      Semantics(
                        header: true,
                        child: Text(title,
                            style: t.headlineMedium?.copyWith(fontSize: 36)),
                      ),
                      const SizedBox(height: RohabSpace.s24),
                      body,
                    ],
                  ),
                ),
                ActionArea(
                  secondary: _step == 0
                      ? null
                      : TextButton(
                          key: WelcomeScreen.backKey,
                          onPressed: () => setState(() => _step--),
                          child: const Text('Back'),
                        ),
                  primary: FilledButton(
                    key: WelcomeScreen.nextKey,
                    onPressed: last
                        ? () => _finish(Routes.baseline)
                        : () => setState(() => _step++),
                    child: Text(switch (_step) {
                      0 => 'Get started',
                      3 => 'Measure my hands',
                      _ => 'Next',
                    }),
                  ),
                ),
                if (last)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        RohabSpace.s24, 0, RohabSpace.s24, RohabSpace.s16),
                    child: TextButton(
                      key: WelcomeScreen.skipKey,
                      onPressed: () => _finish(Routes.home),
                      child: const Text('Do this later'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rohab helps you exercise your hand a little every day, using your '
          "phone's camera.",
          style: t.bodyLarge,
        ),
        const SizedBox(height: RohabSpace.s24),
        const _Fact(Icons.schedule, 'About 10 minutes a day'),
        const _Fact(Icons.back_hand_outlined, 'No equipment needed'),
        const _Fact(Icons.lock_outline, 'Your video is never saved'),
      ],
    );
  }

  Widget _how(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Numbered(1, 'We measure your hands',
              'Open and close each hand twice. It takes about 2 minutes.'),
          _Numbered(2, 'You do your exercises',
              'Short sets, with rests. The camera counts for you.'),
          _Numbered(3, 'You see your progress',
              'Rohab shows how far your hand moves, week by week.'),
        ],
      );

  Widget _care(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Fact(Icons.healing_outlined, 'Stop if anything hurts'),
        const _Fact(Icons.event_seat_outlined, 'Sit comfortably, take your time'),
        const _Fact(Icons.local_hospital_outlined,
            'Ask your therapist before changing your exercises'),
        const SizedBox(height: RohabSpace.s16),
        Text('Rohab is not a medical device.', style: t.labelMedium),
      ],
    );
  }

  Widget _setup(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Fact(Icons.smartphone, 'Lean your phone upright against something'),
          _Fact(Icons.straighten, 'Sit about an arm\'s length away'),
          _Fact(Icons.light_mode_outlined, 'Face a light, not a window behind you'),
          _Fact(Icons.pan_tool_outlined, 'Rest your forearm on a table'),
        ],
      );
}

/// One icon and one sentence.
class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: RohabSpace.s16),
      child: Row(
        children: [
          IconBadge(icon, size: 56),
          const SizedBox(width: RohabSpace.s16),
          Expanded(child: Text(text, style: t.bodyLarge)),
        ],
      ),
    );
  }
}

class _Numbered extends StatelessWidget {
  const _Numbered(this.number, this.title, this.body);

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: RohabSpace.s24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            color: c.accent,
            child: Text('$number',
                style: t.labelLarge?.copyWith(color: c.onAccent)),
          ),
          const SizedBox(width: RohabSpace.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.labelLarge),
                const SizedBox(height: RohabSpace.s8 / 2),
                Text(body, style: t.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
