import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_body.dart';

/// Placeholder. Built in a later session.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const title = 'Settings';

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      description:
          'Set the caregiver PIN, maximum pressure, session length, and reminders.',
    );
  }
}
