import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../exercises/exercise_providers.dart';
import '../../program/pain.dart';
import '../../program/program_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_area.dart';

/// Pain 0-10 before the first set of the day and after the last.
class PainCheckScreen extends ConsumerStatefulWidget {
  const PainCheckScreen({super.key, required this.after, this.next});

  /// After practice (true) or before (false).
  final bool after;

  /// Before only: the exercise to start next.
  final String? next;

  static Key scoreKey(int n) => Key('pain-$n');
  static const primaryKey = Key('pain-primary');
  static const secondaryKey = Key('pain-secondary');

  @override
  ConsumerState<PainCheckScreen> createState() => _PainCheckScreenState();
}

class _PainCheckScreenState extends ConsumerState<PainCheckScreen> {
  int? _score;
  PainAdvice? _advice;
  int? _rise;

  Future<void> _save() async {
    final score = _score!;
    final settings = ref.read(programSettingsProvider);
    final repo = ref.read(programRepositoryProvider);
    final now = ref.read(clockProvider)();
    final phase = widget.after ? 'after' : 'before';
    final before = ref.read(programOverviewProvider).value?.painBefore;
    await repo.savePain(now, phase, score);
    ref.invalidate(programOverviewProvider);
    if (!mounted) return;

    final advice = widget.after
        ? (before == null ? PainAdvice.ok : PainRules.after(before, score, settings))
        : PainRules.before(score, settings);
    if (advice == PainAdvice.ok) {
      _continue();
    } else {
      setState(() {
        _advice = advice;
        _rise = before == null ? null : score - before;
      });
    }
  }

  void _continue() {
    if (widget.after) {
      // End of today's camera session: the next session calibrates again.
      ref.read(cameraSessionRangesProvider.notifier).clear();
      context.go(Routes.cameraExercises);
    } else {
      context.go(widget.next == null
          ? Routes.cameraExercises
          : Routes.cameraExercise(widget.next!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final advice = _advice;

    if (advice == PainAdvice.restToday) {
      return _Layout(
        secondary: TextButton(
          key: PainCheckScreen.secondaryKey,
          onPressed: _continue,
          child: const Text('Practice anyway'),
        ),
        primary: FilledButton(
          key: PainCheckScreen.primaryKey,
          onPressed: () => context.go(Routes.cameraExercises),
          child: const Text('Rest today'),
        ),
        children: [
          Text('Your pain is high today', style: t.headlineMedium),
          const SizedBox(height: RohabSpace.s16),
          Text(
            'Resting is the safer choice. Tell your therapist if the pain '
            'stays high.',
            style: t.bodyLarge,
          ),
        ],
      );
    }
    if (advice == PainAdvice.painRose) {
      return _Layout(
        primary: FilledButton(
          key: PainCheckScreen.primaryKey,
          onPressed: _continue,
          child: const Text('Done'),
        ),
        children: [
          Text('Your pain went up${_rise == null ? '' : ' by $_rise'}',
              style: t.headlineMedium),
          const SizedBox(height: RohabSpace.s16),
          Text(
            "Rest your hand. Tomorrow's goal will be a little lower. Tell "
            'your therapist if the pain stays.',
            style: t.bodyLarge,
          ),
        ],
      );
    }

    return _Layout(
      secondary: widget.after
          ? null
          : TextButton(
              key: PainCheckScreen.secondaryKey,
              onPressed: () => context.go(Routes.cameraExercises),
              child: const Text('Back'),
            ),
      primary: FilledButton(
        key: PainCheckScreen.primaryKey,
        onPressed: _score == null ? null : _save,
        child: Text(widget.after ? 'Save' : 'Continue'),
      ),
      children: [
        // Short copy so all of 0-10 fits above the buttons on a phone.
        Text(widget.after ? 'Pain now?' : 'Pain right now?',
            style: t.headlineMedium),
        const SizedBox(height: RohabSpace.s8),
        Text('In your hand or arm. 0 is none, 10 is the worst.',
            style: t.bodyLarge),
        const SizedBox(height: RohabSpace.s16),
        _ScoreGrid(
          selected: _score,
          onSelected: (n) => setState(() => _score = n),
        ),
      ],
    );
  }
}

/// 0-10 as large, flat buttons: 4 per row, 64 dp tall.
class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, constraints) {
      const perRow = 4;
      final w = (constraints.maxWidth - RohabSpace.s8 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: RohabSpace.s8,
        runSpacing: RohabSpace.s8,
        children: [
          for (var n = 0; n <= 10; n++)
            Semantics(
              button: true,
              selected: selected == n,
              label: 'Pain $n',
              excludeSemantics: true,
              child: SizedBox(
                width: w,
                height: RohabSize.touchTarget,
                child: Material(
                  color: selected == n ? c.accent : c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RohabShape.radius),
                    side: BorderSide(
                        color: selected == n ? c.accent : c.divider,
                        width: RohabShape.border),
                  ),
                  child: InkWell(
                    key: PainCheckScreen.scoreKey(n),
                    borderRadius: BorderRadius.circular(RohabShape.radius),
                    onTap: () => onSelected(n),
                    child: Center(
                      child: Text(
                        '$n',
                        style: t.labelLarge?.copyWith(
                            color: selected == n ? c.onAccent : c.text),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _Layout extends StatelessWidget {
  const _Layout({required this.children, this.primary, this.secondary});

  final List<Widget> children;
  final Widget? primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => Column(
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
