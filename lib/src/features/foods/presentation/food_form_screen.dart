import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eatrun/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import 'foods_providers.dart';

/// Add (foodId null) or edit an existing food.
class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({super.key, this.foodId});

  final String? foodId;

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  // Realistic upper bounds per serving.
  static const _maxCarbs = 1000;
  static const _maxSodium = 10000;
  static const _maxCaffeine = 1000;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _carbs = TextEditingController();
  final _sodium = TextEditingController();
  final _caffeine = TextEditingController();
  final _notes = TextEditingController();
  String? _photoPath;
  bool _loaded = false;

  bool get _isEditing => widget.foodId != null;

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
    final food = await ref.read(foodsRepositoryProvider).findById(widget.foodId!);
    if (food != null) {
      _name.text = food.name;
      _carbs.text = food.carbsGrams.toString();
      _sodium.text = food.sodiumMg.toString();
      _caffeine.text = food.caffeineMg.toString();
      _notes.text = food.notes ?? '';
      _photoPath = food.photoPath;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _carbs.dispose();
    _sodium.dispose();
    _caffeine.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chooseFromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source);
    if (file != null && mounted) setState(() => _photoPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(foodsRepositoryProvider).save(
          id: widget.foodId,
          name: _name.text.trim(),
          photoPath: _photoPath,
          carbsGrams: int.tryParse(_carbs.text) ?? 0,
          sodiumMg: int.tryParse(_sodium.text) ?? 0,
          caffeineMg: int.tryParse(_caffeine.text) ?? 0,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editFood : l10n.newFood)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: _photoPath != null
                        ? Image.file(File(_photoPath!), fit: BoxFit.fitWidth)
                        : const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              size: AppSizes.iconSize,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.fieldName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            _NumberField(
              controller: _carbs,
              label: l10n.fieldCarbs,
              max: _maxCarbs,
            ),
            _NumberField(
              controller: _sodium,
              label: l10n.fieldSodium,
              max: _maxSodium,
            ),
            _NumberField(
              controller: _caffeine,
              label: l10n.fieldCaffeine,
              max: _maxCaffeine,
            ),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l10n.fieldNotes),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.isEmpty) return null; // empty = 0, allowed
        final n = int.tryParse(v);
        return (n != null && n > max) ? l10n.fieldMaxValue(max) : null;
      },
    );
  }
}
