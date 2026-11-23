import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A large, plain seconds countdown. No ring, no animation.
class CountdownNumber extends StatelessWidget {
  const CountdownNumber({super.key, required this.seconds});

  static const valueKey = Key('countdown-value');

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: '$seconds ${seconds == 1 ? 'second' : 'seconds'} left',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$seconds', key: valueKey, style: t.displayLarge),
          const SizedBox(width: RohabSpace.s8),
          Text('s', style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
