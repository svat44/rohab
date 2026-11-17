import 'package:material_ui/material_ui.dart';

import '../glove/glove_service.dart';
import '../ui/app_shell.dart';
import '../ui/theme.dart';
import 'glove_scope.dart';

class RohabApp extends StatelessWidget {
  const RohabApp({super.key, required this.glove});

  final GloveService glove;

  @override
  Widget build(BuildContext context) {
    return GloveScope(
      service: glove,
      child: MaterialApp(
        title: 'Rohab',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const AppShell(),
      ),
    );
  }
}
