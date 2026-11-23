import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_button.dart';

/// Plain words, left aligned, on white. No icon, no illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: context.colors.surface,
    padding: const EdgeInsets.all(RohabSpace.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RohabType.rowTitle),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(message!, style: RohabType.rowSub),
          ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: RohabSpace.s16),
            child: RohabButton(
              label: actionLabel!,
              onPressed: onAction,
              kind: RohabButtonKind.secondary,
            ),
          ),
      ],
    ),
  );
}
