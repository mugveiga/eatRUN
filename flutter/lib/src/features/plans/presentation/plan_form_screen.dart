import 'package:eatrun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/tables.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/slider_input.dart';
import 'plans_providers.dart';

/// The three interdependent workout metrics. Any two determine the third.
enum _Metric { distance, duration, pace }

/// Pace as m:ss (e.g. 5.5 min/km → "5:30").
String _formatPace(double minutesPerKm) {
  final totalSeconds = (minutesPerKm * 60).round();
  return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
}

/// Parse "m:ss" (or a plain number) into decimal minutes.
double? _parsePace(String text) {
  if (text.contains(':')) {
    final parts = text.split(':');
    final m = int.tryParse(parts[0]) ?? 0;
    final s = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return m + s / 60;
  }
  return double.tryParse(text);
}

/// Masks digit input into m:ss as the user types (last two digits = seconds).
class _PaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    var digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final out = digits.length <= 2
        ? digits
        : '${digits.substring(0, digits.length - 2)}:'
            '${digits.substring(digits.length - 2)}';
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// Step 1 of plan creation: the plan's parameters. The intake-tracking mode
/// (by distance or time) and food picking happen on the matching screen.
class PlanFormScreen extends ConsumerStatefulWidget {
  const PlanFormScreen({super.key, this.planId});

  /// When set, the form edits an existing plan instead of creating one.
  final String? planId;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  static const _distMin = 5.0, _distMax = 100.0;
  static const _durMin = 30.0, _durMax = 600.0; // minutes (30 min – 10 h)
  static const _paceMin = 3.0, _paceMax = 12.0; // run, min/km
  static const _speedMin = 10.0, _speedMax = 50.0; // bike, km/h

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _comments = TextEditingController();

  DateTime _date = DateTime.now();
  ActivityType _activity = ActivityType.run;

  // Workout metrics start empty; syncing begins once two are filled.
  double? _distance;
  double? _duration;
  double? _pace; // min/km (run) or km/h (bike)
  final List<_Metric> _filled = []; // user-set metrics, most recent first

  double _carbs = 60;
  double _sodium = 500;
  double _caffeine = 0;

  // Preserved across an edit so saving initial settings doesn't wipe the
  // intake tracking chosen later. Null for a new plan.
  PlanType? _planType;
  double? _intakeInterval;

  bool get _isEditing => widget.planId != null;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final plan =
        await ref.read(plansRepositoryProvider).findPlan(widget.planId!);
    if (plan != null) {
      _name.text = plan.name;
      _date = plan.date;
      _activity = plan.activityType;
      _distance = plan.distanceKm;
      _duration = plan.durationMinutes.toDouble();
      _pace = _isRun
          ? _duration! / _distance!
          : 60 * _distance! / _duration!;
      _filled
        ..clear()
        ..addAll([_Metric.duration, _Metric.distance]); // both filled → ready
      _carbs = plan.targetCarbsPerHour;
      _sodium = plan.targetSodiumPerHour;
      _caffeine = plan.targetCaffeinePerHour;
      _planType = plan.planType;
      _intakeInterval = plan.intakeInterval;
      _comments.text = plan.comments ?? '';
    }
    if (mounted) setState(() => _loaded = true);
  }

  bool get _isRun => _activity == ActivityType.run;
  double get _paceLo => _isRun ? _paceMin : _speedMin;
  double get _paceHi => _isRun ? _paceMax : _speedMax;

  /// Two filled metrics → the third is derived and we can compute intake.
  bool get _ready => _filled.length >= 2;

  void _assign(_Metric m, double v) => switch (m) {
        _Metric.distance => _distance = v,
        _Metric.duration => _duration = v,
        _Metric.pace => _pace = v,
      };

  void _set(_Metric m, double value) {
    setState(() {
      _assign(m, value);
      _filled
        ..remove(m)
        ..insert(0, m);
      if (_filled.length >= 2) _recompute();
    });
  }

  /// Recompute the least-recently-set metric from the two most recent.
  void _recompute() {
    final kept = _filled.take(2).toSet();
    final derived = _Metric.values.firstWhere((m) => !kept.contains(m));
    final d = _distance, t = _duration, p = _pace;
    switch (derived) {
      case _Metric.pace:
        _pace = (_isRun ? t! / d! : 60 * d! / t!).clamp(_paceLo, _paceHi);
      case _Metric.duration:
        _duration = (_isRun ? p! * d! : 60 * d! / p!).clamp(_durMin, _durMax);
      case _Metric.distance:
        _distance = (_isRun ? t! / p! : p! * t! / 60).clamp(_distMin, _distMax);
    }
  }

  void _setActivity(ActivityType a) {
    setState(() {
      _activity = a;
      // Pace/speed is activity-specific: recompute from distance+duration if
      // both are known, otherwise drop it.
      _filled.remove(_Metric.pace);
      if (_distance != null && _duration != null) {
        _pace = (_isRun ? _duration! / _distance! : 60 * _distance! / _duration!)
            .clamp(_paceLo, _paceHi);
        for (final m in [_Metric.distance, _Metric.duration]) {
          if (!_filled.contains(m)) _filled.add(m);
        }
      } else {
        _pace = null;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
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
    await ref.read(plansRepositoryProvider).savePlan(
          id: widget.planId,
          name: _name.text.trim(),
          date: _date,
          activityType: _activity,
          distanceKm: _distance!,
          durationMinutes: _duration!.round(),
          targetCarbsPerHour: _carbs,
          targetSodiumPerHour: _sodium,
          targetCaffeinePerHour: _caffeine,
          planType: _planType,
          intakeInterval: _intakeInterval,
          comments:
              _comments.text.trim().isEmpty ? null : _comments.text.trim(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editPlan : l10n.newPlan)),
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
              _Card(
                children: [
                  if (!_ready) ...[
                    Text(
                      l10n.planWorkoutHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
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
                    onSelectionChanged: (s) => _setActivity(s.first),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SliderInput(
                    label: l10n.planLengthDistance,
                    value: _distance,
                    min: _distMin,
                    max: _distMax,
                    divisions: 95,
                    onChanged: (v) => _set(_Metric.distance, v),
                  ),
                  SliderInput(
                    label: l10n.planLengthDuration,
                    value: _duration,
                    min: _durMin,
                    max: _durMax,
                    divisions: 114,
                    onChanged: (v) => _set(_Metric.duration, v),
                  ),
                  SliderInput(
                    label: _isRun ? l10n.planPace : l10n.planSpeed,
                    value: _pace,
                    min: _paceLo,
                    max: _paceHi,
                    divisions: _isRun ? 108 : 40,
                    decimals: _isRun ? 1 : 0,
                    formatValue: _isRun ? _formatPace : null,
                    parseValue: _isRun ? _parsePace : null,
                    inputFormatter: _isRun ? _PaceInputFormatter() : null,
                    onChanged: (v) => _set(_Metric.pace, v),
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
                  SliderInput(
                    label: l10n.targetCarbs,
                    value: _carbs,
                    min: 20,
                    max: 120,
                    divisions: 20,
                    onChanged: (v) => setState(() => _carbs = v),
                  ),
                  SliderInput(
                    label: l10n.targetSodium,
                    value: _sodium,
                    min: 200,
                    max: 2000,
                    divisions: 36,
                    onChanged: (v) => setState(() => _sodium = v),
                  ),
                  SliderInput(
                    label: l10n.targetCaffeine,
                    value: _caffeine,
                    min: 0,
                    max: 200,
                    divisions: 20,
                    onChanged: (v) => setState(() => _caffeine = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _comments,
                decoration: InputDecoration(labelText: l10n.planComments),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _ready ? _save : null,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A padded card holding a column of form controls.
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
