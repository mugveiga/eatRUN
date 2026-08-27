import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database.dart';
import '../../../core/database/sync.dart';
import 'foods_dao.dart';

/// The offline-first seam. Today it only talks to the local DAO; when the
/// backend arrives, remote read/write and a sync queue live here — the UI
/// above never changes.
class FoodsRepository {
  FoodsRepository(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FoodsDao _dao;
  final Uuid _uuid;

  Stream<List<Food>> watchFoods() => _dao.watchFoods();

  Future<Food?> findById(String id) => _dao.findById(id);

  /// Create (id null) or update an existing food. Stamps sync metadata.
  Future<void> save({
    String? id,
    required String name,
    String? photoPath,
    double carbsGrams = 0,
    double sodiumMg = 0,
    double caffeineMg = 0,
    String? notes,
  }) {
    return _dao.upsert(
      FoodsCompanion(
        id: Value(id ?? _uuid.v4()),
        name: Value(name),
        photoPath: Value(photoPath),
        carbsGrams: Value(carbsGrams),
        sodiumMg: Value(sodiumMg),
        caffeineMg: Value(caffeineMg),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  Future<void> delete(String id) => _dao.softDelete(id);
}
