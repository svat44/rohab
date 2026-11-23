import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../widgets/skeuo.dart';
import '../settings/settings_controller.dart';
import 'providers.dart';
import 'router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref.watch(sharedPreferencesProvider));
  ref.onDispose(router.dispose);
  return router;
});

class RohabApp extends ConsumerWidget {
  const RohabApp({super.key});

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
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear((system * scale).clamp(1.0, 2.0)),
          ),
          // Linen cloth behind every screen.
          child: _Backdrop(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Linen cloth behind every screen. Loads the textures once, up front.
class _Backdrop extends StatefulWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  State<_Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<_Backdrop> {
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) {
      _loading = true;
      Textures.precache();
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: linenDecoration(context.colors),
    child: widget.child,
  );
}
