import 'package:drift/native.dart';
import 'package:eatrun/src/core/database/database.dart';
import 'package:eatrun/src/features/foods/data/foods_dao.dart';
import 'package:eatrun/src/features/foods/data/foods_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save then watch returns the food', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = FoodsRepository(FoodsDao(db));

    await repo.save(name: 'Gel', carbsGrams: 25, sodiumMg: 50, caffeineMg: 0);
    final foods = await repo.watchFoods().first;

    expect(foods, hasLength(1));
    expect(foods.single.name, 'Gel');
    expect(foods.single.carbsGrams, 25);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
