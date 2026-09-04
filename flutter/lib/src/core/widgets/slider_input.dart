import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A slider paired with a type-in field, both bound to one nullable value.
/// A null value shows an empty field and the slider parked at [min].
class SliderInput extends StatefulWidget {
  const SliderInput({
    super.key,
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
  State<SliderInput> createState() => _SliderInputState();
}

class _SliderInputState extends State<SliderInput> {
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
  void didUpdateWidget(covariant SliderInput old) {
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

  String _fieldText() => widget.value == null ? '' : _display(widget.value!);

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
