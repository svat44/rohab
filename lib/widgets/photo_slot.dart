import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Placeholder for an instruction photo: 400 x 240 dp, narrower on small
/// phones with the same shape, 1 dp border, caption below.
/// Set to true once real instruction photos are bundled.
const bool kPhotosAvailable = false;

class PhotoSlot extends StatelessWidget {
  const PhotoSlot({super.key, required this.caption});

  static const width = 400.0;
  static const height = 240.0;

  final String caption;

  @override
  Widget build(BuildContext context) {
    // No placeholder on screen: until a real photo is added, show nothing.
    if (!kPhotosAvailable) return const SizedBox.shrink();
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: width),
            child: AspectRatio(
              aspectRatio: width / height,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border:
                      Border.all(color: c.divider, width: RohabShape.border),
                  borderRadius: BorderRadius.circular(RohabShape.radius),
                ),
                alignment: Alignment.center,
                child: Text('Photo to come', style: t.labelMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: RohabSpace.s8),
        Text(caption, style: t.labelMedium),
      ],
    );
  }
}
