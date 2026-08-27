import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'sync.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Foods, Plans, PlanItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'eatrun'));

  @override
  int get schemaVersion => 1;
}
