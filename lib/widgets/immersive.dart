import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while a camera step is on screen: the title row and bottom
/// navigation hide so the camera gets the space. The STOP banner never
/// hides.
final immersiveProvider = NotifierProvider<ImmersiveNotifier, bool>(
  ImmersiveNotifier.new,
);

class ImmersiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}

/// Mixin for a screen that goes immersive during some steps.
mixin ImmersiveScreen<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final ImmersiveNotifier _immersive = ref.read(
    immersiveProvider.notifier,
  );

  /// Call from build with whether the current step is a camera step.
  void setImmersive(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _immersive.set(value);
    });
  }

  /// Call from dispose.
  void clearImmersive() {
    final notifier = _immersive;
    Future<void>.microtask(() {
      try {
        notifier.set(false);
      } on Object {
        // The app is shutting down.
      }
    });
  }
}
