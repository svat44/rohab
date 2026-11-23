import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'bottom_nav.dart';
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

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    NavDestination('Home', Icons.home),
    NavDestination('Glove', Icons.bluetooth),
    NavDestination('Exercises', Icons.back_hand),
    NavDestination('Progress', Icons.bar_chart),
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
    final window = WindowClass.of(context);
    final sideNav = window.usesSideNav && !immersive;
    return PopScope(
      canPop: !_settingsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _settingsOpen) _shell.goBranch(_lastTab);
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The header colour runs up under the status bar, so the title bar has no
            // gap above it.
            if (!immersive)
              _StatusBarFill(height: MediaQuery.paddingOf(context).top)
            else
              SizedBox(height: MediaQuery.paddingOf(context).top),
            const SafetyBanner(),
            if (!immersive)
              _Header(
                title: AppShell.titles[_shell.currentIndex],
                settingsOpen: _settingsOpen,
                onToggleSettings: _toggleSettings,
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sideNav)
                    SideNav(
                      destinations: _tabs,
                      selectedIndex: _settingsOpen
                          ? null
                          : _shell.currentIndex,
                      onSelected: _goTab,
                    ),
                  // Wide windows keep a readable column instead of
                  // stretching lines across the whole width.
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: window.contentMaxWidth,
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
            ),
          ],
        ),
        bottomNavigationBar: immersive || window.usesSideNav
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

class _StatusBarFill extends StatelessWidget {
  const _StatusBarFill({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: context.colors.header),
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

    // Keep the header compact so it leaves room for the screen content.
    return DecoratedBox(
      decoration: BoxDecoration(color: c.header),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: RohabSize.touchTarget),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            RohabSpace.s16,
            RohabSpace.s8 / 2,
            RohabSpace.s8,
            RohabSpace.s8 / 2,
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
                        style: t.labelMedium?.copyWith(color: Colors.white),
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
                child: IconButton(
                  key: settingsOpen
                      ? AppShell.closeSettingsKey
                      : AppShell.settingsButtonKey,
                  onPressed: onToggleSettings,
                  constraints: const BoxConstraints.tightFor(
                    width: RohabSize.touchTarget,
                    height: RohabSize.touchTarget,
                  ),
                  iconSize: RohabSize.icon,
                  color: c.accent,
                  icon: Icon(settingsOpen ? Icons.close : Icons.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
