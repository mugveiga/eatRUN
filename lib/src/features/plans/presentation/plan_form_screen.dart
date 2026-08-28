import 'package:eatrun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/tables.dart';
import '../../../core/theme/app_spacing.dart';
import 'plans_providers.dart';

/// Step 1 of plan creation: the plan's parameters. The intake-tracking mode
/// (by distance or time) and food picking happen on the matching screen.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key});

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _distance = TextEditingController();
  final _duration = TextEditingController();
  final _carbs = TextEditingController();
  final _sodium = TextEditingController();
  final _caffeine = TextEditingController();
  final _comments = TextEditingController();

  DateTime _date = DateTime.now();
  ActivityType _activity = ActivityType.run;

  @override
  void dispose() {
    _name.dispose();
    _distance.dispose();
    _duration.dispose();
    _carbs.dispose();
    _sodium.dispose();
    _caffeine.dispose();
    _comments.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(plansRepositoryProvider)
        .savePlan(
          name: _name.text.trim(),
          date: _date,
          activityType: _activity,
          distanceKm: double.parse(_distance.text),
          durationMinutes: int.parse(_duration.text),
          targetCarbsPerHour: double.tryParse(_carbs.text) ?? 0,
          targetSodiumPerHour: double.tryParse(_sodium.text) ?? 0,
          targetCaffeinePerHour: double.tryParse(_caffeine.text) ?? 0,
          comments: _comments.text.trim().isEmpty
              ? null
              : _comments.text.trim(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPlan)),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.fieldName),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.planDate),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<ActivityType>(
                segments: [
                  ButtonSegment(
                    value: ActivityType.run,
                    label: Text(l10n.activityRun),
                    icon: const Icon(Icons.directions_run),
                  ),
                  ButtonSegment(
                    value: ActivityType.bike,
                    label: Text(l10n.activityBike),
                    icon: const Icon(Icons.directions_bike),
                  ),
                ],
                selected: {_activity},
                onSelectionChanged: (s) => setState(() => _activity = s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              _NumField(
                controller: _distance,
                label: l10n.planLengthDistance,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n <= 0) ? l10n.fieldRequired : null;
                },
              ),
              _NumField(
                controller: _duration,
                label: l10n.planLengthDuration,
                decimal: false,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? l10n.fieldRequired : null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.targetsPerHour,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _NumField(controller: _carbs, label: l10n.targetCarbs),
              _NumField(controller: _sodium, label: l10n.targetSodium),
              _NumField(controller: _caffeine, label: l10n.targetCaffeine),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _comments,
                decoration: InputDecoration(labelText: l10n.planComments),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: _save, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.decimal = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
    );
  }
}
