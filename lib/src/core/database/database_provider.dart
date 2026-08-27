import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database.dart';

part 'database_provider.g.dart';

/// Single app-wide database instance. `keepAlive` so it isn't torn down
/// between screens. Shared DI root — every feature's repositories watch it.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
