import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_body.dart';

/// Placeholder. Built in a later session.
class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({super.key});

  static const title = 'Calibration';

  @override
  Widget build(BuildContext context) {
    return const PlaceholderBody(
      description:
          'Record your muscle signal at rest and while gripping, so the glove knows when to start helping.',
    );
  }
}
