import 'package:material_ui/material_ui.dart';

import 'screens/calibration_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/safety_banner.dart';

/// Frame for every screen: safety banner on top, page title, body,
/// bottom navigation. Settings opens from the title row and keeps the
/// banner, so STOP is reachable everywhere.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const settingsButtonKey = Key('open-settings');
  static const closeSettingsKey = Key('close-settings');

  @override
  State<AppShell> createState() => _AppShellState();
}

class _Page {
  const _Page(this.title, this.body);
  final String title;
  final Widget body;
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    NavDestination('Home', Icons.home_outlined),
    NavDestination('Calibrate', Icons.tune),
    NavDestination('Exercises', Icons.back_hand_outlined),
    NavDestination('Progress', Icons.show_chart),
  ];

  static const _pages = [
    _Page(HomeScreen.title, HomeScreen()),
    _Page(CalibrationScreen.title, CalibrationScreen()),
    _Page(ExercisesScreen.title, ExercisesScreen()),
    _Page(ProgressScreen.title, ProgressScreen()),
    _Page(SettingsScreen.title, SettingsScreen()),
  ];
  static const _settingsIndex = 4;

  int _tab = 0;
  bool _settingsOpen = false;

  int get _pageIndex => _settingsOpen ? _settingsIndex : _tab;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];

    return PopScope(
      canPop: !_settingsOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _settingsOpen = false);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SafetyBanner(),
              _TitleRow(
                title: page.title,
                settingsOpen: _settingsOpen,
                onToggleSettings: () =>
                    setState(() => _settingsOpen = !_settingsOpen),
              ),
              Expanded(
                child: IndexedStack(
                  index: _pageIndex,
                  children: [for (final p in _pages) p.body],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNav(
          destinations: _tabs,
          selectedIndex: _settingsOpen ? null : _tab,
          onSelected: (i) => setState(() {
            _tab = i;
            _settingsOpen = false;
          }),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.settingsOpen,
    required this.onToggleSettings,
  });

  final String title;
  final bool settingsOpen;
  final VoidCallback onToggleSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s3, Space.s2, Space.s1, Space.s2),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),
          SizedBox.square(
            dimension: Sizes.touchTarget,
            child: IconButton(
              key: settingsOpen
                  ? AppShell.closeSettingsKey
                  : AppShell.settingsButtonKey,
              tooltip: settingsOpen ? 'Close settings' : 'Settings',
              onPressed: onToggleSettings,
              iconSize: 28,
              color: c.text,
              icon: Icon(settingsOpen ? Icons.close : Icons.settings_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
