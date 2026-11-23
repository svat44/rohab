import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import 'bottom_nav.dart';
import 'skeuo.dart';
import 'immersive.dart';
import '../debug/debug_menu.dart';
import 'safety_banner.dart';

/// Frame for every screen: STOP banner, "Rohab" wordmark, screen title,
/// screen body, bottom navigation. Settings opens from the gear and keeps
/// the banner, so STOP is reachable everywhere.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const settingsButtonKey = Key('open-settings');
  static const closeSettingsKey = Key('close-settings');
  static const wordmarkKey = Key('rohab-wordmark');

  // Branch order matches lib/app/router.dart.
  static const titles = ['Home', 'Glove', 'Exercises', 'Progress', 'Settings'];
  static const settingsBranch = 4;
  static const maxWidth = 640.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    NavDestination('Home', Icons.home_outlined),
    NavDestination('Glove', Icons.tune),
    NavDestination('Exercises', Icons.back_hand_outlined),
    NavDestination('Progress', Icons.show_chart),
  ];

  int _lastTab = 0;

  StatefulNavigationShell get _shell => widget.shell;
  bool get _settingsOpen => _shell.currentIndex == AppShell.settingsBranch;

  void _goTab(int index) {
    _lastTab = index;
    _shell.goBranch(index);
  }

  void _toggleSettings() {
    if (_settingsOpen) {
      _shell.goBranch(_lastTab);
    } else {
      _lastTab = _shell.currentIndex;
      _shell.goBranch(AppShell.settingsBranch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final immersive = ref.watch(immersiveProvider);
    return PopScope(
      canPop: !_settingsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _settingsOpen) _shell.goBranch(_lastTab);
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Leather runs up under the status bar, so the title bar has no
            // gap above it.
            if (!immersive)
              _StatusBarLeather(height: MediaQuery.paddingOf(context).top)
            else
              SizedBox(height: MediaQuery.paddingOf(context).top),
            const SafetyBanner(),
            if (!immersive)
              _Header(
                title: AppShell.titles[_shell.currentIndex],
                settingsOpen: _settingsOpen,
                onToggleSettings: _toggleSettings,
              ),
            // Wide screens (tablets, landscape web) keep a readable column
            // instead of stretching lines across the whole width.
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppShell.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: RohabSpace.s16),
                    child: _shell,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: immersive
            ? null
            : BottomNav(
                destinations: _tabs,
                selectedIndex: _settingsOpen ? null : _shell.currentIndex,
                onSelected: _goTab,
              ),
      ),
    );
  }
}

class _StatusBarLeather extends StatelessWidget {
  const _StatusBarLeather({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: leatherDecoration(context.colors),
    child: SizedBox(height: height),
  );
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.title,
    required this.settingsOpen,
    required this.onToggleSettings,
  });

  final String title;
  final bool settingsOpen;
  final VoidCallback onToggleSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final glove = ref.watch(gloveServiceProvider);
    const engraved = [Shadow(color: Color(0xB0000000), offset: Offset(0, -1))];

    // Blue leather bar with a stitched seam: the screen title on the left
    // (small wordmark above it), a labelled Settings button on the right.
    return DecoratedBox(
      decoration: leatherDecoration(c).copyWith(
        border: const Border(
          bottom: BorderSide(color: Color(0xAA000000), width: 2),
        ),
        boxShadow: raisedShadow(c, lift: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: RohabSize.touchTarget + RohabSpace.s16,
        ),
        child: Stack(
          children: [
            Positioned(
              left: RohabSpace.s8,
              right: RohabSpace.s8,
              bottom: 5,
              height: 3,
              child: const CustomPaint(
                painter: StitchPainter(Color(0x66FFFFFF)),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppShell.maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RohabSpace.s16,
                    RohabSpace.s8 / 2,
                    RohabSpace.s8,
                    RohabSpace.s16 / 2 + RohabSpace.s8 / 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              key: AppShell.wordmarkKey,
                              behavior: HitTestBehavior.opaque,
                              onLongPress: kDebugMode
                                  ? () => showDebugMenu(
                                      context,
                                      mockGlove: glove is MockGloveService
                                          ? glove
                                          : null,
                                    )
                                  : null,
                              child: Text(
                                RohabTokens.name,
                                style: t.labelMedium?.copyWith(
                                  color: const Color(0xFFCFE3F3),
                                  shadows: engraved,
                                ),
                              ),
                            ),
                            Semantics(
                              header: true,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  style: t.headlineMedium?.copyWith(
                                    fontSize: 30,
                                    height: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: settingsOpen ? 'Close settings' : 'Settings',
                        child: TextButton.icon(
                          key: settingsOpen
                              ? AppShell.closeSettingsKey
                              : AppShell.settingsButtonKey,
                          onPressed: onToggleSettings,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              RohabSize.touchTarget,
                              RohabSize.touchTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: RohabSpace.s16,
                            ),
                          ),
                          icon: Icon(
                            settingsOpen
                                ? Icons.close
                                : Icons.settings_outlined,
                            size: RohabSize.icon - 4,
                          ),
                          label: Text(
                            settingsOpen ? 'Close' : 'Settings',
                            maxLines: 1,
                            softWrap: false,
                            style: t.labelMedium?.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
