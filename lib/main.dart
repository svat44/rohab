import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/glove_service_factory.dart';

void main() {
  runApp(RohabApp(glove: createGloveService()));
}
