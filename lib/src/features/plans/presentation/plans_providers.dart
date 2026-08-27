import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/database.dart';
import '../../../core/database/database_provider.dart';
import '../data/plans_dao.dart';
import '../data/plans_repository.dart';

part 'plans_providers.g.dart';

@Riverpod(keepAlive: true)
PlansRepository plansRepository(Ref ref) {
  return PlansRepository(PlansDao(ref.watch(appDatabaseProvider)));
}

/// Reactive list of plans. Hand-written (returns the Drift-generated `Plan`
/// type, which the Riverpod generator can't resolve — see foods_providers).
final plansListProvider = StreamProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).watchPlans();
});

/// Reactive timeline items for one plan, keyed by plan id.
final planItemsProvider =
    StreamProvider.autoDispose.family<List<PlanItem>, String>((ref, planId) {
  return ref.watch(plansRepositoryProvider).watchItems(planId);
});
