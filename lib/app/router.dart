import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show Widget;

import '../screens/calibration/calibration_screen.dart';
import '../screens/exercises/camera_exercise_flow.dart';
import '../screens/exercises/exercises_screen.dart';
import '../screens/home_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/app_shell.dart';

class Routes {
  Routes._();
  static const home = '/home';
  static const calibration = '/calibration';
  static const exercises = '/exercises';
  static const cameraExercises = '/exercises/camera';
  static String cameraExercise(String id) => '/exercises/camera/$id';
  static const progress = '/progress';
  static const settings = '/settings';
}

/// One branch per screen, kept alive in an IndexedStack so a running
/// calibration survives a tab switch. AppShell wraps every branch, so the
/// STOP banner is on every screen.
GoRouter buildRouter() => GoRouter(
      initialLocation: Routes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
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
                      pageBuilder: (context, state) => const NoTransitionPage(
                          child: CameraExerciseListScreen()),
                      routes: [
                        GoRoute(
                          path: ':exerciseId',
                          pageBuilder: (context, state) => NoTransitionPage(
                            key: state.pageKey,
                            child: CameraExerciseFlow(
                              exerciseId:
                                  state.pathParameters['exerciseId']!,
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
            _branch(Routes.settings, const SettingsScreen()),
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
