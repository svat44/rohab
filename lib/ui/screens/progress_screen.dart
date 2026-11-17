import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_body.dart';

/// Placeholder. Built in a later session.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const title = 'Progress';

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      description:
          'See your reps, session minutes, and muscle signal over the past week, month, or 3 months.',
    );
  }
}
