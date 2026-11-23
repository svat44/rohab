import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// SQLite file in the app's private support folder, opened off the UI
/// thread.
QueryExecutor? openAppDatabase() => LazyDatabase(() async {
  final dir = await getApplicationSupportDirectory();
  return NativeDatabase.createInBackground(File('${dir.path}/rohab.sqlite'));
});
