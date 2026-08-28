import 'package:eatrun/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/tables.dart';
import '../../../core/theme/app_spacing.dart';
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
  const PlanFormScreen({super.key});

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
          name: _name.text.trim(),
          date: _date,
          activityType: _activity,
          distanceKm: _distance!,
          durationMinutes: _duration!.round(),
          targetCarbsPerHour: _carbs,
          targetSodiumPerHour: _sodium,
          targetCaffeinePerHour: _caffeine,
          comments:
              _comments.text.trim().isEmpty ? null : _comments.text.trim(),
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
                  _SliderInput(
                    label: l10n.planLengthDistance,
                    value: _distance,
                    min: _distMin,
                    max: _distMax,
                    divisions: 95,
                    onChanged: (v) => _set(_Metric.distance, v),
                  ),
                  _SliderInput(
                    label: l10n.planLengthDuration,
                    value: _duration,
                    min: _durMin,
                    max: _durMax,
                    divisions: 114,
                    onChanged: (v) => _set(_Metric.duration, v),
                  ),
                  _SliderInput(
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
                  _SliderInput(
                    label: l10n.targetCarbs,
                    value: _carbs,
                    min: 20,
                    max: 120,
                    divisions: 20,
                    onChanged: (v) => setState(() => _carbs = v),
                  ),
                  _SliderInput(
                    label: l10n.targetSodium,
                    value: _sodium,
                    min: 200,
                    max: 2000,
                    divisions: 36,
                    onChanged: (v) => setState(() => _sodium = v),
                  ),
                  _SliderInput(
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

/// A slider paired with a type-in field, both bound to one nullable value.
/// A null value shows an empty field and the slider parked at [min].
class _SliderInput extends StatefulWidget {
  const _SliderInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.decimals = 0,
    this.formatValue,
    this.parseValue,
    this.inputFormatter,
  });

  final String label;
  final double? value;
  final double min;
  final double max;
  final int? divisions;
  final int decimals;
  final ValueChanged<double> onChanged;
  final String Function(double)? formatValue;
  final double? Function(String)? parseValue;
  final TextInputFormatter? inputFormatter;

  @override
  State<_SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends State<_SliderInput> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _fieldText());
    _focus.addListener(() {
      if (!_focus.hasFocus) _controller.text = _fieldText();
    });
  }

  @override
  void didUpdateWidget(covariant _SliderInput old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != old.value) {
      _controller.text = _fieldText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _display(double v) {
    final c = v.clamp(widget.min, widget.max);
    return widget.formatValue?.call(c) ?? c.toStringAsFixed(widget.decimals);
  }

  String _fieldText() =>
      widget.value == null ? '' : _display(widget.value!);

  void _onField(String s) {
    final n = (widget.parseValue ?? double.tryParse)(s);
    if (n != null) widget.onChanged(n.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final v = (widget.value ?? widget.min).clamp(widget.min, widget.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label)),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textAlign: TextAlign.end,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  widget.inputFormatter ??
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(isDense: true),
                onChanged: _onField,
              ),
            ),
          ],
        ),
        Slider(
          value: v,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: _display(v),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
