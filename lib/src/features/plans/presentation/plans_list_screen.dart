import 'package:eatrun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/database/tables.dart';
import '../../../core/theme/app_spacing.dart';
import 'plans_providers.dart';

class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plans = ref.watch(plansListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPlans)),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.genericError(e.toString()))),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _PlanTile(plan: items[i]),
          );
        },
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd().format(plan.date);
    final length = _formatNum(plan.length);
    final lengthLabel = plan.planType == PlanType.distance
        ? l10n.planDistanceKm(length)
        : l10n.planDurationMin(length);
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.event_note)),
      title: Text(plan.name),
      subtitle: Text('$date · $lengthLabel'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref.read(plansRepositoryProvider).deletePlan(plan.id),
      ),
    );
  }

  String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          AppLocalizations.of(context)!.noPlansYet,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
