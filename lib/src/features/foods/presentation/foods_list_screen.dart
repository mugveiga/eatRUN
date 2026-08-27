import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eatrun/l10n/app_localizations.dart';

import '../../../core/database/database.dart';
import '../../../core/theme/app_spacing.dart';
import 'foods_providers.dart';

class FoodsListScreen extends ConsumerWidget {
  const FoodsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foods = ref.watch(foodsListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myFoods)),
      body: foods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.genericError(e.toString()))),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _FoodTile(food: items[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/foods/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addFood),
      ),
    );
  }
}

class _FoodTile extends ConsumerWidget {
  const _FoodTile({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: _Thumbnail(path: food.photoPath),
      title: Text(food.name),
      subtitle: Text(
        l10n.foodNutrition(
          food.carbsGrams.toString(),
          food.sodiumMg.toString(),
          food.caffeineMg.toString(),
        ),
      ),
      onTap: () => context.push('/foods/${food.id}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () =>
            ref.read(foodsRepositoryProvider).delete(food.id),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return const CircleAvatar(child: Icon(Icons.restaurant));
    }
    return CircleAvatar(backgroundImage: FileImage(File(path!)));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          AppLocalizations.of(context)!.noFoodsYet,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
