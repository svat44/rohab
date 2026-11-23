import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Opening screen: the name on a solid blue page, for about a second. A tap
/// skips it, and it is skipped when the phone asks for reduced motion.
/// Nothing moves.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 1200);

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  bool _finished = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      Future<void>.delayed(StartupSplash.duration, _finish);
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Semantics(
        label: 'Rohab is starting. Tap to skip.',
        child: ColoredBox(
          color: c.accent,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(RohabSpace.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    RohabTokens.name,
                    style: t.displayLarge?.copyWith(color: c.onAccent),
                  ),
                  const SizedBox(height: RohabSpace.s8),
                  Text(
                    'Hand exercises, every day',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(color: c.onAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
