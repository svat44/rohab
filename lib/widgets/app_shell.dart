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

/// Frame for every screen: STOP banner, a compact title, screen body and
/// bottom navigation. Settings opens from the compact title line.
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
                      selectedIndex: _settingsOpen ? null : _shell.currentIndex,
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
    final glove = ref.watch(gloveServiceProvider);
    final key = settingsOpen
        ? AppShell.closeSettingsKey
        : AppShell.settingsButtonKey;
    return Semantics(
      button: true,
      label: settingsOpen ? 'Close settings' : 'Open settings',
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onToggleSettings,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s16),
            child: Center(
              child: GestureDetector(
                key: AppShell.wordmarkKey,
                behavior: HitTestBehavior.opaque,
                onLongPress: kDebugMode
                    ? () => showDebugMenu(
                        context,
                        mockGlove: glove is MockGloveService ? glove : null,
                      )
                    : null,
                child: Text(
                  '$title · Rohab',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
