import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_body.dart';

/// Placeholder. Built in a later session.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  static const title = 'Exercises';

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      description:
          'Choose assisted grip, passive range of motion, or mirror mode, and follow the steps for each.',
    );
  }
}
