import 'package:flutter/widgets.dart';

import '../glove/glove_service.dart';

/// Makes the [GloveService] available to every screen.
class GloveScope extends InheritedWidget {
  const GloveScope({super.key, required this.service, required super.child});

  final GloveService service;

  static GloveService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GloveScope>();
    assert(scope != null, 'No GloveScope above this widget.');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(GloveScope oldWidget) =>
      service != oldWidget.service;
}
