import 'package:drift/drift.dart';

/// Local sync state of a row. Everything starts [pending] until a future
/// backend confirms it as [synced]. Backend-agnostic on purpose.
enum SyncStatus { pending, synced }

/// Columns every syncable entity shares. Mixed into each table so the
/// offline-first metadata is defined once.
///
/// - [id]        client-generated UUID, globally unique so it survives sync.
/// - [updatedAt] drives last-write-wins conflict handling later.
/// - [deletedAt] soft delete: we sync "was deleted", never a missing row.
/// - [syncStatus] whether local changes are still to be pushed.
/// - [userId]    null until Google login scopes the data to a user.
mixin SyncColumns on Table {
  TextColumn get id => text()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get syncStatus =>
      intEnum<SyncStatus>().withDefault(Constant(SyncStatus.pending.index))();

  TextColumn get userId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
