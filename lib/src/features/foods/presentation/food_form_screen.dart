import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'foods_providers.dart';

/// Add (foodId null) or edit an existing food.
class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({super.key, this.foodId});

  final String? foodId;

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
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
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(foodsRepositoryProvider).save(
          id: widget.foodId,
          name: _name.text.trim(),
          photoPath: _photoPath,
          carbsGrams: double.tryParse(_carbs.text) ?? 0,
          sodiumMg: double.tryParse(_sodium.text) ?? 0,
          caffeineMg: double.tryParse(_caffeine.text) ?? 0,
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit food' : 'New food')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 44,
                backgroundImage:
                    _photoPath != null ? FileImage(File(_photoPath!)) : null,
                child: _photoPath == null
                    ? const Icon(Icons.add_a_photo, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _NumberField(controller: _carbs, label: 'Carbs (g)'),
            _NumberField(controller: _sodium, label: 'Sodium (mg)'),
            _NumberField(controller: _caffeine, label: 'Caffeine (mg)'),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
