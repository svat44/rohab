import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../widgets/startup_splash.dart';
import '../settings/settings_controller.dart';
import 'providers.dart';
import 'router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref.watch(sharedPreferencesProvider));
  ref.onDispose(router.dispose);
  return router;
});

class RohabApp extends ConsumerWidget {
  const RohabApp({super.key, this.showSplash = false});

  /// The opening animation. On in the real app, off in tests.
  final bool showSplash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(thresholdSyncProvider);
    return MaterialApp.router(
      title: RohabTokens.name,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      // The chosen text size multiplies the phone's own text size.
      builder: (context, child) {
        final scale = ref.watch(textSizeProvider).scale;
        final mq = MediaQuery.of(context);
        final system = mq.textScaler.scale(1.0);
        // Tablets get larger text so it is read at the same size at arm's
        // length. The total stays between 1x and 2x so layouts survive it.
        final boost = WindowClass.ofWidth(mq.size.width).textBoost;
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              (system * scale * boost).clamp(1.0, 2.0),
            ),
          ),
          child: _Backdrop(
            showSplash: showSplash,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// The plain page colour behind every screen, with the opening screen on
/// top until it finishes.
class _Backdrop extends StatefulWidget {
  const _Backdrop({required this.child, required this.showSplash});

  final bool showSplash;

  final Widget child;

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop> {
  late bool _splash = widget.showSplash;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.background,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_splash)
          StartupSplash(onDone: () => setState(() => _splash = false)),
      ],
    ),
  );
}
