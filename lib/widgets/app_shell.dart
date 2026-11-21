import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import 'bottom_nav.dart';
import 'immersive.dart';
import 'debug_presets_sheet.dart';
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
  static const titles = [
    'Home',
    'Calibration',
    'Exercises',
    'Progress',
    'Settings',
  ];
  static const settingsBranch = 4;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    NavDestination('Home', Icons.home_outlined),
    NavDestination('Calibrate', Icons.tune),
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
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SafetyBanner(),
              if (!immersive)
                _Header(
                  title: AppShell.titles[_shell.currentIndex],
                  settingsOpen: _settingsOpen,
                  onToggleSettings: _toggleSettings,
                ),
              Expanded(child: _shell),
            ],
          ),
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
    final presets = kDebugMode && glove is MockGloveService;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, RohabSpace.s8, RohabSpace.s8, RohabSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: AppShell.wordmarkKey,
                  behavior: HitTestBehavior.opaque,
                  onLongPress: presets
                      ? () => showDebugPresets(context, glove)
                      : null,
                  child: Text(
                    RohabTokens.name,
                    style: t.labelLarge,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: RohabSize.touchTarget,
                child: IconButton(
                  key: settingsOpen
                      ? AppShell.closeSettingsKey
                      : AppShell.settingsButtonKey,
                  tooltip: settingsOpen ? 'Close settings' : 'Settings',
                  onPressed: onToggleSettings,
                  iconSize: RohabSize.icon,
                  color: c.text,
                  icon: Icon(
                      settingsOpen ? Icons.close : Icons.settings_outlined),
                ),
              ),
            ],
          ),
          Semantics(
            header: true,
            child: Text(title, style: t.headlineMedium),
          ),
        ],
      ),
    );
  }
}
