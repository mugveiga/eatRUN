import 'package:eatrun/src/app.dart';
import 'package:eatrun/src/core/database/database.dart';
import 'package:eatrun/src/features/foods/presentation/foods_providers.dart';
import 'package:eatrun/src/features/plans/presentation/plans_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the empty Foods screen', (tester) async {
    // Stub the foods stream so the widget test never touches the real DB;
    // persistence is covered separately in foods_dao_test.dart.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodsListProvider.overrideWith((ref) => Stream.value(const <Food>[])),
          plansListProvider.overrideWith((ref) => Stream.value(const <Plan>[])),
        ],
        child: const EatRunApp(),
      ),
    );
    await tester.pump(); // Stream.value emits on the first microtask

    expect(find.text('My Foods'), findsOneWidget);
    expect(find.textContaining('No foods yet'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
