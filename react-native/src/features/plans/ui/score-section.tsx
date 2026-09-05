import { useTranslation } from 'react-i18next';
import { View } from 'react-native';
import { Card, ProgressBar, Text } from 'react-native-paper';

import type { Plan } from '@/core/db/schema';
import { useFoods } from '@/features/foods/data/use-foods';
import { usePlanItems } from '../data/use-plans';
import { perHourTotals, scoreRatio } from '../logic/score';

/// Compares the placed foods' actual carbs/sodium/caffeine per hour against the
/// plan's per-hour targets. Reactive: re-rolls as items change.
export function ScoreSection({ plan }: { plan: Plan }) {
  const { t } = useTranslation();
  const { data: placed } = usePlanItems(plan.id);
  const { data: foods } = useFoods();
  const byId = new Map(foods.map((f) => [f.id, f]));
  const per = perHourTotals(placed, byId, plan.durationMinutes);

  return (
    <Card>
      <Card.Content style={{ gap: 8 }}>
        <Text variant="titleMedium">{t('plans.score')}</Text>
        <ScoreRow
          label={t('plans.targetCarbs')}
          actual={per.carbs}
          target={plan.targetCarbsPerHour}
        />
        <ScoreRow
          label={t('plans.targetSodium')}
          actual={per.sodium}
          target={plan.targetSodiumPerHour}
        />
        <ScoreRow
          label={t('plans.targetCaffeine')}
          actual={per.caffeine}
          target={plan.targetCaffeinePerHour}
        />
      </Card.Content>
    </Card>
  );
}

function ScoreRow(props: { label: string; actual: number; target: number }) {
  const { label, actual, target } = props;
  return (
    <View style={{ gap: 4 }}>
      <View style={{ flexDirection: 'row' }}>
        <Text style={{ flex: 1 }}>{label}</Text>
        <Text variant="titleMedium">
          {`${Math.round(actual)} / ${Math.round(target)}`}
        </Text>
      </View>
      <ProgressBar progress={scoreRatio(actual, target)} />
    </View>
  );
}
