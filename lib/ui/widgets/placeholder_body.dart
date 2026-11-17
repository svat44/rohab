import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Body for screens not built yet: one plain sentence under the title.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.s3, 0, Space.s3, Space.s3),
      children: [
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
