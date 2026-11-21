import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/router.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import '../widgets/debug_presets_sheet.dart';
import 'diagnostics_overlay.dart';

/// Debug builds only. Opened by a long-press on the "Rohab" title.
///
/// Not modal on purpose: a modal barrier would block the STOP button.
void showDebugMenu(BuildContext context, {MockGloveService? mockGlove}) {
  late final PersistentBottomSheetController controller;
  controller = Scaffold.of(context).showBottomSheet(
    (sheetContext) => _DebugMenu(
      mockGlove: mockGlove,
      close: () => controller.close(),
      pageContext: context,
    ),
  );
}

class _DebugMenu extends ConsumerWidget {
  const _DebugMenu({
    required this.mockGlove,
    required this.close,
    required this.pageContext,
  });

  static const diagnosticsKey = Key('debug-diagnostics');
  static const protocolKey = Key('debug-protocol');
  static const gripKey = Key('debug-grip');

  final MockGloveService? mockGlove;
  final VoidCallback close;
  final BuildContext pageContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final on = ref.watch(diagnosticsEnabledProvider);
    Widget row(Key key, String title, String detail, VoidCallback onTap) =>
        InkWell(
          key: key,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: RohabSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.bodyLarge),
                  Text(detail, style: t.labelMedium),
                ],
              ),
            ),
          ),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(RohabSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Debug', style: t.labelLarge),
            row(
              diagnosticsKey,
              'Diagnostics overlay: ${on ? 'on' : 'off'}',
              'Shows live tracking numbers on the next exercise.',
              () => ref.read(diagnosticsEnabledProvider.notifier).toggle(),
            ),
            row(
              protocolKey,
              'Test protocol',
              'Records 30 s of three hand poses and prints a summary.',
              () {
                close();
                pageContext.go(Routes.testProtocol);
              },
            ),
            if (mockGlove != null)
              row(
                gripKey,
                'Simulated grip',
                'Choose Strong, Weak or No signal.',
                () {
                  close();
                  showDebugPresets(pageContext, mockGlove!);
                },
              ),
            TextButton(onPressed: close, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
