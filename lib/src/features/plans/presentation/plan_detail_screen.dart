import 'package:eatrun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../../core/database/tables.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/slider_input.dart';
import '../../foods/presentation/foods_providers.dart';
import 'plans_providers.dart';

/// Pace as m:ss (mirrors the form).
String _formatPace(double minutesPerKm) {
  final totalSeconds = (minutesPerKm * 60).round();
  return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider(planId));
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.value?.name ?? ''),
        actions: [
          if (plan.value != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppLocalizations.of(context)!.editPlan,
              onPressed: () => context.push('/plans/$planId/edit'),
            ),
        ],
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(AppLocalizations.of(context)!.genericError(e.toString())),
        ),
        data: (p) => p == null
            ? const SizedBox.shrink()
            : _Detail(plan: p, planId: planId),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.plan, required this.planId});

  final Plan plan;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRun = plan.activityType == ActivityType.run;
    final pace = plan.durationMinutes / plan.distanceKm; // min/km
    final speed = plan.distanceKm / (plan.durationMinutes / 60); // km/h

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Card(
            children: [
              Row(
                children: [
                  Icon(isRun ? Icons.directions_run : Icons.directions_bike),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat.yMMMd().format(plan.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Row(l10n.planLengthDistance, _num(plan.distanceKm)),
              _Row(l10n.planLengthDuration, plan.durationMinutes.toString()),
              _Row(
                isRun ? l10n.planPace : l10n.planSpeed,
                isRun ? _formatPace(pace) : _num(speed),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Card(
            children: [
              Text(
                l10n.targetsPerHour,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Row(l10n.targetCarbs, _num(plan.targetCarbsPerHour)),
              _Row(l10n.targetSodium, _num(plan.targetSodiumPerHour)),
              _Row(l10n.targetCaffeine, _num(plan.targetCaffeinePerHour)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _IntakeSection(plan: plan),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.planTimeline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (plan.planType == null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.noIntakeYet, textAlign: TextAlign.center),
            )
          else
            _Timeline(plan: plan, planId: planId),
          const SizedBox(height: AppSpacing.lg),
          _Score(plan: plan, planId: planId),
          if (plan.comments != null && plan.comments!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(plan.comments!),
          ],
        ],
      ),
    );
  }
}

/// The intake timeline. The interval seeds suggested empty slots (held in
/// local state, not the DB); placing a food persists a PlanItem at that offset
/// and consumes the slot, so moving the item later never reopens it. The "+"
/// adds extra slots beyond the initial guess.
class _Timeline extends ConsumerStatefulWidget {
  const _Timeline({required this.plan, required this.planId});

  final Plan plan;
  final String planId;

  @override
  ConsumerState<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends ConsumerState<_Timeline> {
  List<double>?
  _empties; // suggested empty slots, seeded once from the interval

  bool get _isDistance => widget.plan.planType == PlanType.distance;
  double get _length => _isDistance
      ? widget.plan.distanceKm
      : widget.plan.durationMinutes.toDouble();
  double get _interval => widget.plan.intakeInterval ?? 0;

  List<double> _seed(List<PlanItem> placed) {
    final out = <double>[];
    for (
      var o = _interval;
      o <= _length + 1e-6 && out.length < 200;
      o += _interval
    ) {
      if (!placed.any((it) => (it.offsetLength - o).abs() < 1e-6)) out.add(o);
    }
    return out;
  }

  double _maxOffset(List<PlanItem> placed) {
    var m = 0.0;
    for (final it in placed) {
      if (it.offsetLength > m) m = it.offsetLength;
    }
    for (final o in _empties!) {
      if (o > m) m = o;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(planItemsProvider(widget.planId));
    final foods = ref.watch(foodsListProvider);

    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(l10n.genericError(e.toString())),
      data: (placed) {
        if (_interval <= 0) return Text(l10n.noIntakeYet);
        // Seed the interval guesses only for a fresh timeline; once the user
        // has placed anything, respect their layout and suggest nothing.
        _empties ??= placed.isEmpty ? _seed(placed) : <double>[];
        final byId = {for (final f in foods.value ?? <Food>[]) f.id: f};

        final rows = <(double, PlanItem?)>[
          for (final it in placed) (it.offsetLength, it),
          for (final o in _empties!) (o, null),
        ]..sort((a, b) => a.$1.compareTo(b.$1));

        return Column(
          children: [
            for (final (offset, item) in rows) _tile(l10n, offset, item, byId),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _empties!.add(
                    (_maxOffset(placed) + _interval).clamp(0, _length),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.addIntakePoint),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(
    AppLocalizations l10n,
    double offset,
    PlanItem? item,
    Map<String, Food> byId,
  ) {
    final offsetLabel = _isDistance
        ? l10n.planDistanceKm(_num(offset))
        : l10n.planDurationMin(_num(offset));
    final leading = SizedBox(width: 64, child: Text(offsetLabel));

    if (item == null) {
      return ListTile(
        leading: leading,
        title: Text(l10n.addFood),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(
            () => _empties!.removeWhere((e) => (e - offset).abs() < 1e-6),
          ),
        ),
        onTap: () => _addFood(offset),
      );
    }
    final food = byId[item.foodId];
    final qty = item.quantity;
    return ListTile(
      leading: leading,
      title: Text('${food?.name ?? '—'}  ×${_num(qty)}'),
      subtitle: food == null
          ? null
          : Text(
              l10n.foodNutrition(
                (food.carbsGrams * qty).round().toString(),
                (food.sodiumMg * qty).round().toString(),
                (food.caffeineMg * qty).round().toString(),
              ),
            ),
      onTap: () => _fineTune(item),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref.read(plansRepositoryProvider).deleteItem(item.id),
      ),
    );
  }

  Future<void> _addFood(double offset) async {
    final foods = ref.read(foodsListProvider).value ?? <Food>[];
    final l10n = AppLocalizations.of(context)!;
    if (foods.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noFoodsYet)));
      return;
    }
    final picked = await showModalBottomSheet<Food>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in foods)
              ListTile(
                title: Text(f.name),
                subtitle: Text(
                  l10n.foodNutrition(
                    f.carbsGrams.toString(),
                    f.sodiumMg.toString(),
                    f.caffeineMg.toString(),
                  ),
                ),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref
          .read(plansRepositoryProvider)
          .saveItem(
            planId: widget.planId,
            foodId: picked.id,
            offsetLength: offset,
          );
      // Consume the slot so moving the item later won't reopen it.
      setState(() => _empties!.removeWhere((e) => (e - offset).abs() < 1e-6));
    }
  }

  void _fineTune(PlanItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ItemEditor(
          item: item,
          isDistance: _isDistance,
          length: _length,
        ),
      ),
    );
  }
}

/// Bottom-sheet editor to fine-tune a placed item's position and servings.
class _ItemEditor extends ConsumerStatefulWidget {
  const _ItemEditor({
    required this.item,
    required this.isDistance,
    required this.length,
  });

  final PlanItem item;
  final bool isDistance;
  final double length;

  @override
  ConsumerState<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends ConsumerState<_ItemEditor> {
  late double _offset = widget.item.offsetLength.clamp(0, widget.length);
  late double _quantity = widget.item.quantity.clamp(1, 10);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SliderInput(
              label: widget.isDistance
                  ? l10n.itemPositionDistance
                  : l10n.itemPositionTime,
              value: _offset,
              min: 0,
              max: widget.length,
              divisions: widget.length.round().clamp(1, 300),
              onChanged: (v) => setState(() => _offset = v),
            ),
            SliderInput(
              label: l10n.itemServings,
              value: _quantity,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _quantity = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(plansRepositoryProvider)
                    .updateItem(
                      id: widget.item.id,
                      offsetLength: _offset,
                      quantity: _quantity,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choose how intake is tracked (by distance or time) and the interval.
class _IntakeSection extends ConsumerStatefulWidget {
  const _IntakeSection({required this.plan});

  final Plan plan;

  @override
  ConsumerState<_IntakeSection> createState() => _IntakeSectionState();
}

class _IntakeSectionState extends ConsumerState<_IntakeSection> {
  PlanType? _mode;
  late double _interval;
  late bool _editing;

  @override
  void initState() {
    super.initState();
    _mode = widget.plan.planType;
    _interval = widget.plan.intakeInterval ?? _defaultInterval(_mode);
    _editing = widget.plan.planType == null;
  }

  static double _defaultInterval(PlanType? mode) =>
      mode == PlanType.duration ? 20 : 5;

  bool get _isDistance => _mode == PlanType.distance;
  double get _intMin => _isDistance ? 1 : 5;
  double get _intMax => _isDistance ? 10 : 60;

  void _selectMode(PlanType mode) => setState(() {
    _mode = mode;
    _interval = _defaultInterval(mode);
  });

  Future<void> _save() async {
    await ref
        .read(plansRepositoryProvider)
        .setIntakeTracking(
          id: widget.plan.id,
          planType: _mode!,
          interval: _interval,
        );
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_editing && widget.plan.planType != null) {
      final mode = widget.plan.planType!;
      final interval = widget.plan.intakeInterval ?? 0;
      final summary = mode == PlanType.distance
          ? l10n.intakeEveryKm(_num(interval))
          : l10n.intakeEveryMin(_num(interval));
      return _Card(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.intakeTracking,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _editing = true),
                child: Text(l10n.change),
              ),
            ],
          ),
          Text(summary),
        ],
      );
    }

    return _Card(
      children: [
        Text(l10n.planIntakeQuestion),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<PlanType>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: PlanType.distance,
              label: Text(l10n.intakeByDistance),
              icon: const Icon(Icons.straighten),
            ),
            ButtonSegment(
              value: PlanType.duration,
              label: Text(l10n.intakeByTime),
              icon: const Icon(Icons.timer_outlined),
            ),
          ],
          selected: _mode == null ? const {} : {_mode!},
          onSelectionChanged: (s) => _selectMode(s.first),
        ),
        if (_mode != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SliderInput(
            label: _isDistance
                ? l10n.planIntakeIntervalDistance
                : l10n.planIntakeIntervalDuration,
            value: _interval,
            min: _intMin,
            max: _intMax,
            divisions: _isDistance ? 9 : 11,
            onChanged: (v) => setState(() => _interval = v),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: _mode == null ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Rolls placed foods into actual carbs/sodium/caffeine per hour and shows
/// them against the plan's targets.
class _Score extends ConsumerWidget {
  const _Score({required this.plan, required this.planId});

  final Plan plan;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final placed = ref.watch(planItemsProvider(planId)).value ?? <PlanItem>[];
    final byId = {
      for (final f in ref.watch(foodsListProvider).value ?? <Food>[]) f.id: f,
    };

    var carbs = 0.0, sodium = 0.0, caffeine = 0.0;
    for (final it in placed) {
      final f = byId[it.foodId];
      if (f == null) continue;
      carbs += f.carbsGrams * it.quantity;
      sodium += f.sodiumMg * it.quantity;
      caffeine += f.caffeineMg * it.quantity;
    }
    final hours = plan.durationMinutes / 60;
    double perHour(double total) => hours > 0 ? total / hours : 0;

    return _Card(
      children: [
        Text(l10n.scoreTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _ScoreRow(l10n.targetCarbs, perHour(carbs), plan.targetCarbsPerHour),
        _ScoreRow(l10n.targetSodium, perHour(sodium), plan.targetSodiumPerHour),
        _ScoreRow(
          l10n.targetCaffeine,
          perHour(caffeine),
          plan.targetCaffeinePerHour,
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.actual, this.target);

  final String label;
  final double actual;
  final double target;

  @override
  Widget build(BuildContext context) {
    final ratio = target > 0
        ? (actual / target).clamp(0.0, 1.0)
        : (actual > 0 ? 1.0 : 0.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '${actual.round()} / ${target.round()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
