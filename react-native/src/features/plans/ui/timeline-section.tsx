import { useEffect, useState } from 'react';
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

import { SliderInput } from '@/core/widgets/slider-input';
import type { Food, Plan, PlanItem } from '@/core/db/schema';
import { useFoods } from '@/features/foods/data/use-foods';
import {
  deleteItem,
  listItems,
  saveItem,
  updateItem,
} from '../data/plans-repository';
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
  // null until the one-shot mount read decides whether to seed. Suggestions are
  // seeded only for a fresh timeline; once any item exists we respect the
  // user's layout and suggest nothing new (placing consumes its slot).
  const [empties, setEmpties] = useState<number[] | null>(null);
  const [pending, setPending] = useState<number | null>(null);
  const [editing, setEditing] = useState<PlanItem | null>(null);

  useEffect(() => {
    let alive = true;
    listItems(plan.id).then((existing) => {
      if (alive) {
        setEmpties(existing.length === 0 ? seedSlots(interval, length) : []);
      }
    });
    return () => {
      alive = false;
    };
  }, [plan.id, interval, length]);

  const slots = empties ?? [];
  const byId = new Map(foods.map((f) => [f.id, f]));
  const occupied = placed.map((p) => p.offsetLength);
  // Drop suggestions that collide with a placed item or with an earlier
  // suggestion, so no two rows ever share an offset (or a React key).
  const shown: number[] = [];
  for (const o of slots) {
    if (!occupies(o, occupied) && !occupies(o, shown)) shown.push(o);
  }
  const rows: Row[] = [
    ...placed.map((item) => ({ offset: item.offsetLength, item })),
    ...shown.map((offset) => ({ offset, item: null })),
  ].sort((a, b) => a.offset - b.offset);

  const dismiss = (offset: number) =>
    setEmpties((prev) => (prev ?? []).filter((o) => !occupies(o, [offset])));
  const addPoint = () => {
    const max = Math.max(0, ...occupied, ...slots);
    const next = Math.min(max + interval, length);
    if (occupies(next, [...occupied, ...slots])) return; // already a point there
    setEmpties((prev) => [...(prev ?? []), next]);
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
          onEdit={setEditing}
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
      {editing && (
        <ItemEditor
          item={editing}
          length={length}
          isDistance={isDistance}
          onDismiss={() => setEditing(null)}
        />
      )}
    </View>
  );
}

function TimelineTile(props: {
  row: Row;
  food: Food | undefined;
  isDistance: boolean;
  onAdd: (offset: number) => void;
  onEdit: (item: PlanItem) => void;
  onDelete: (id: string) => void;
  onDismiss: (offset: number) => void;
}) {
  const { row, food, isDistance, onAdd, onEdit, onDelete, onDismiss } = props;
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
      onPress={() => onEdit(row.item!)}
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

/// Fine-tune a placed item's position on the timeline and its servings.
function ItemEditor(props: {
  item: PlanItem;
  length: number;
  isDistance: boolean;
  onDismiss: () => void;
}) {
  const { item, length, isDistance, onDismiss } = props;
  const { t } = useTranslation();
  const theme = useTheme();
  const [offset, setOffset] = useState(Math.min(item.offsetLength, length));
  const [quantity, setQuantity] = useState(Math.min(Math.max(item.quantity, 1), 10));

  const save = async () => {
    await updateItem({ id: item.id, offsetLength: offset, quantity });
    onDismiss();
  };

  return (
    <Portal>
      <Modal
        visible
        onDismiss={onDismiss}
        contentContainerStyle={[
          styles.modal,
          { backgroundColor: theme.colors.background, padding: 16, gap: 12 },
        ]}
      >
        <SliderInput
          label={t(isDistance ? 'plans.positionDistance' : 'plans.positionTime')}
          value={offset}
          min={0}
          max={length}
          step={isDistance ? 0.5 : 1}
          onChange={setOffset}
        />
        <SliderInput
          label={t('plans.servings')}
          value={quantity}
          min={1}
          max={10}
          step={1}
          onChange={setQuantity}
        />
        <Button mode="contained" onPress={save}>
          {t('common.save')}
        </Button>
      </Modal>
    </Portal>
  );
}

const styles = StyleSheet.create({
  offset: { alignSelf: 'center', width: 64, textAlign: 'left' },
  modal: { margin: 16, borderRadius: 12, maxHeight: '70%' },
});
