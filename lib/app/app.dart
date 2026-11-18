import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
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
    );
  }
}
