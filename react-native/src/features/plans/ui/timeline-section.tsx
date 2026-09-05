import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ScrollView, StyleSheet, View } from 'react-native';
import {
  Button,
  IconButton,
  List,
  Modal,
  Portal,
  Text,
  useTheme,
} from 'react-native-paper';

import type { Food, Plan, PlanItem } from '@/core/db/schema';
import { useFoods } from '@/features/foods/data/use-foods';
import { deleteItem, saveItem } from '../data/plans-repository';
import { usePlanItems } from '../data/use-plans';
import { occupies, seedSlots } from '../logic/timeline';

const num = (v: number): string =>
  Number.isInteger(v) ? String(v) : String(Number(v.toFixed(1)));

type Row = { offset: number; item: PlanItem | null };

/// The intake timeline. Interval-seeded empty slots (local state) suggest where
/// to fuel; tapping one opens a food picker and persists a PlanItem there,
/// consuming the slot. Placed items already on the plan take their own slots.
export function TimelineSection({ plan }: { plan: Plan }) {
  const { t } = useTranslation();
  const isDistance = plan.planType === 'distance';
  const length = isDistance ? plan.distanceKm : plan.durationMinutes;
  const interval = plan.intakeInterval ?? 0;

  const { data: placed } = usePlanItems(plan.id);
  const { data: foods } = useFoods();
  const [empties, setEmpties] = useState(() => seedSlots(interval, length));
  const [pending, setPending] = useState<number | null>(null);

  const byId = new Map(foods.map((f) => [f.id, f]));
  const occupied = placed.map((p) => p.offsetLength);
  const rows: Row[] = [
    ...placed.map((item) => ({ offset: item.offsetLength, item })),
    ...empties
      .filter((o) => !occupies(o, occupied))
      .map((offset) => ({ offset, item: null })),
  ].sort((a, b) => a.offset - b.offset);

  const dismiss = (offset: number) =>
    setEmpties((prev) => prev.filter((o) => !occupies(o, [offset])));
  const addPoint = () => {
    const max = Math.max(0, ...occupied, ...empties);
    setEmpties((prev) => [...prev, Math.min(max + interval, length)]);
  };
  const pick = async (foodId: string) => {
    if (pending == null) return;
    await saveItem({ planId: plan.id, foodId, offsetLength: pending });
    dismiss(pending);
    setPending(null);
  };

  return (
    <View style={{ gap: 2 }}>
      <Text variant="titleMedium" style={{ marginBottom: 4 }}>
        {t('plans.timeline')}
      </Text>
      {rows.map((r) => (
        <TimelineTile
          key={r.item ? r.item.id : `slot-${r.offset}`}
          row={r}
          food={r.item ? byId.get(r.item.foodId) : undefined}
          isDistance={isDistance}
          onAdd={setPending}
          onDelete={deleteItem}
          onDismiss={dismiss}
        />
      ))}
      <Button
        icon="plus"
        onPress={addPoint}
        style={{ alignSelf: 'flex-start' }}
      >
        {t('plans.addIntakePoint')}
      </Button>
      <FoodPicker
        visible={pending != null}
        foods={foods}
        onDismiss={() => setPending(null)}
        onPick={pick}
      />
    </View>
  );
}

function TimelineTile(props: {
  row: Row;
  food: Food | undefined;
  isDistance: boolean;
  onAdd: (offset: number) => void;
  onDelete: (id: string) => void;
  onDismiss: (offset: number) => void;
}) {
  const { row, food, isDistance, onAdd, onDelete, onDismiss } = props;
  const { t } = useTranslation();
  const label = isDistance
    ? t('plans.distanceValue', { km: num(row.offset) })
    : t('plans.durationValue', { min: num(row.offset) });
  const offset = () => <Text style={styles.offset}>{label}</Text>;

  if (!row.item) {
    return (
      <List.Item
        title={t('plans.addFood')}
        left={offset}
        right={() => (
          <IconButton icon="close" onPress={() => onDismiss(row.offset)} />
        )}
        onPress={() => onAdd(row.offset)}
      />
    );
  }
  const qty = row.item.quantity;
  const sub = food
    ? t('foods.nutrition', {
        carbs: Math.round(food.carbsGrams * qty),
        sodium: Math.round(food.sodiumMg * qty),
        caffeine: Math.round(food.caffeineMg * qty),
      })
    : undefined;
  return (
    <List.Item
      title={`${food?.name ?? '—'}  ×${num(qty)}`}
      description={sub}
      left={offset}
      right={() => (
        <IconButton
          icon="delete-outline"
          onPress={() => onDelete(row.item!.id)}
        />
      )}
    />
  );
}

function FoodPicker(props: {
  visible: boolean;
  foods: Food[];
  onDismiss: () => void;
  onPick: (foodId: string) => void;
}) {
  const { visible, foods, onDismiss, onPick } = props;
  const { t } = useTranslation();
  const theme = useTheme();
  return (
    <Portal>
      <Modal
        visible={visible}
        onDismiss={onDismiss}
        contentContainerStyle={[
          styles.modal,
          { backgroundColor: theme.colors.background },
        ]}
      >
        {foods.length === 0 ? (
          <Text style={{ padding: 24, textAlign: 'center' }}>
            {t('foods.empty')}
          </Text>
        ) : (
          <ScrollView>
            {foods.map((f) => (
              <List.Item
                key={f.id}
                title={f.name}
                description={t('foods.nutrition', {
                  carbs: f.carbsGrams,
                  sodium: f.sodiumMg,
                  caffeine: f.caffeineMg,
                })}
                onPress={() => onPick(f.id)}
              />
            ))}
          </ScrollView>
        )}
      </Modal>
    </Portal>
  );
}

const styles = StyleSheet.create({
  offset: { alignSelf: 'center', width: 64, textAlign: 'left' },
  modal: { margin: 16, borderRadius: 12, maxHeight: '70%' },
});
