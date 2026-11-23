import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../debug/debug_menu.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import 'immersive.dart';
import 'rohab_app_bar.dart';
import 'rohab_icon.dart';
import 'rohab_nav_bar.dart';
import 'safety_banner.dart';

/// Frame for every screen: top bar (tab roots and Settings only; sub-screens
/// draw their own with a back arrow), the screen, the pinned glove STOP bar
/// while a glove is connected, and the bottom tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell, this.location = ''});

  final StatefulNavigationShell shell;

  /// Current URL path, so the shell knows whether a sub-screen is open.
  final String location;

  static const settingsButtonKey = Key('open-settings');
  static const closeSettingsKey = Key('close-settings');
  static const wordmarkKey = Key('rohab-wordmark');

  // Branch order matches lib/app/router.dart.
  static const titles = ['Today', 'Glove', 'Exercises', 'Progress', 'Settings'];
  static const settingsBranch = 4;
  static const _rootPaths = {
    '/home',
    '/calibration',
    '/exercises',
    '/progress',
    '/settings',
  };

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    NavDestination('Today', RohabIconData.today),
    NavDestination('Glove', RohabIconData.glove),
    NavDestination('Exercises', RohabIconData.hand),
    NavDestination('Progress', RohabIconData.chart),
  ];

  int _lastTab = 0;

  StatefulNavigationShell get _shell => widget.shell;
  bool get _settingsOpen => _shell.currentIndex == AppShell.settingsBranch;

  void _goTab(int index) {
    _lastTab = index;
    // Tapping the current tab returns to its first screen.
    _shell.goBranch(index, initialLocation: index == _shell.currentIndex);
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
    final glove = ref.watch(gloveServiceProvider);
    final isRoot =
        AppShell._rootPaths.contains(widget.location) ||
        widget.location.isEmpty;
    final title = AppShell.titles[_shell.currentIndex];
    return PopScope(
      canPop: !_settingsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _settingsOpen) _shell.goBranch(_lastTab);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!immersive && isRoot)
                  Builder(
                    builder: (context) => GestureDetector(
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
                      child: RohabAppBar(
                        title: title,
                        eyebrow: _shell.currentIndex == 0
                            ? RohabTokens.name
                            : null,
                        onBack: _settingsOpen ? _toggleSettings : null,
                        onSettings: _toggleSettings,
                        settingsKey: AppShell.settingsButtonKey,
                        backButtonKey: AppShell.closeSettingsKey,
                      ),
                    ),
                  ),
                const GloveFaultNotice(),
                Expanded(child: _shell),
              ],
            ),
            // STOP sign, top right, over everything, only while the glove is
            // active.
            const Positioned(top: 0, right: 56, child: SafetyBanner()),
          ],
        ),
        bottomNavigationBar: immersive
            ? null
            : RohabNavBar(
                destinations: _tabs,
                selectedIndex: _settingsOpen ? null : _shell.currentIndex,
                onSelected: _goTab,
              ),
      ),
    );
  }
}
