import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show Widget;
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/onboarding.dart';
import '../screens/welcome_screen.dart';

import '../debug/test_protocol_screen.dart';
import '../screens/calibration/calibration_screen.dart';
import '../screens/exercises/camera_exercise_flow.dart';
import '../screens/exercises/exercise_setup_screen.dart';
import '../screens/exercises/exercises_screen.dart';
import '../screens/home_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/exercises/baseline_screen.dart';
import '../screens/exercises/pain_check_screen.dart';
import '../screens/exercises/program_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/therapist_screen.dart';
import '../widgets/app_shell.dart';

class Routes {
  Routes._();
  static const welcome = '/welcome';
  static const home = '/home';
  static const calibration = '/calibration';
  static const exercises = '/exercises';
  static const cameraExercises = '/exercises/camera';
  static const allCameraExercises = '/exercises/camera/all';
  static const testProtocol = '/exercises/camera/test-protocol';
  static const baseline = '/exercises/camera/baseline';
  static String exerciseSetup(String id) => '/exercises/camera/setup/$id';
  static String cameraExercise(
    String id, {
    int? reps,
    int? sets,
    int? rest,
    int? set,
  }) {
    final q = [
      if (reps != null) 'reps=$reps',
      if (sets != null) 'sets=$sets',
      if (rest != null) 'rest=$rest',
      if (set != null) 'set=$set',
    ];
    return '/exercises/camera/$id${q.isEmpty ? '' : '?${q.join('&')}'}';
  }

  static String painCheck(String phase, {String? next}) =>
      '/exercises/camera/pain?phase=$phase${next == null ? '' : '&next=$next'}';
  static const therapist = '/settings/therapist';
  static const progress = '/progress';
  static const settings = '/settings';
}

/// One branch per screen, kept alive in an IndexedStack so a running
/// calibration survives a tab switch. AppShell wraps every branch, so the
/// STOP banner is on every screen.
GoRouter buildRouter(SharedPreferences prefs) => GoRouter(
  initialLocation: Routes.home,
  // First run: the guide comes before anything else.
  redirect: (context, state) {
    final onWelcome = state.matchedLocation == Routes.welcome;
    if (!isOnboardingDone(prefs) && !onWelcome) return Routes.welcome;
    return null;
  },
  routes: [
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: WelcomeScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AppShell(shell: shell, location: state.uri.path),
      branches: [
        _branch(Routes.home, const HomeScreen()),
        _branch(Routes.calibration, const CalibrationScreen()),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.exercises,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ExercisesScreen()),
              routes: [
                GoRoute(
                  path: 'camera',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ProgramScreen()),
                  routes: [
                    GoRoute(
                      path: 'all',
                      pageBuilder: (context, state) => const NoTransitionPage(
                        child: CameraExerciseListScreen(),
                      ),
                    ),
                    // Debug builds only; opened from the debug menu.
                    if (kDebugMode)
                      GoRoute(
                        path: 'test-protocol',
                        pageBuilder: (context, state) => NoTransitionPage(
                          key: state.pageKey,
                          child: const TestProtocolScreen(),
                        ),
                      ),
                    GoRoute(
                      path: 'baseline',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const BaselineScreen(),
                      ),
                    ),
                    GoRoute(
                      path: 'pain',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: PainCheckScreen(
                          after: state.uri.queryParameters['phase'] == 'after',
                          next: state.uri.queryParameters['next'],
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'setup/:exerciseId',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: ExerciseSetupScreen(
                          exerciseId: state.pathParameters['exerciseId']!,
                        ),
                      ),
                    ),
                    GoRoute(
                      path: ':exerciseId',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: CameraExerciseFlow(
                          exerciseId: state.pathParameters['exerciseId']!,
                          reps: int.tryParse(
                            state.uri.queryParameters['reps'] ?? '',
                          ),
                          sets: int.tryParse(
                            state.uri.queryParameters['sets'] ?? '',
                          ),
                          rest: int.tryParse(
                            state.uri.queryParameters['rest'] ?? '',
                          ),
                          set: int.tryParse(
                            state.uri.queryParameters['set'] ?? '',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _branch(Routes.progress, const ProgressScreen()),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsScreen()),
              routes: [
                GoRoute(
                  path: 'therapist',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const TherapistScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(child: screen),
    ),
  ],
);
