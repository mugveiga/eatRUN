// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_dao.dart';

// ignore_for_file: type=lint
mixin _$PlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlansTable get plans => attachedDatabase.plans;
  $FoodsTable get foods => attachedDatabase.foods;
  $PlanItemsTable get planItems => attachedDatabase.planItems;
  PlansDaoManager get managers => PlansDaoManager(this);
}

class PlansDaoManager {
  final _$PlansDaoMixin _db;
  PlansDaoManager(this._db);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db.attachedDatabase, _db.plans);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db.attachedDatabase, _db.foods);
  $$PlanItemsTableTableManager get planItems =>
      $$PlanItemsTableTableManager(_db.attachedDatabase, _db.planItems);
}
