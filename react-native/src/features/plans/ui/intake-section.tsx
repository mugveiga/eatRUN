import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { View } from 'react-native';
import { Button, Card, SegmentedButtons, Text } from 'react-native-paper';

import { SliderInput } from '@/core/widgets/slider-input';
import type { Plan, PlanType } from '@/core/db/schema';
import { setIntakeTracking } from '../data/plans-repository';

const defaultInterval = (mode: PlanType): number =>
  mode === 'duration' ? 20 : 5;
const num = (v: number): string =>
  Number.isInteger(v) ? String(v) : String(Number(v.toFixed(1)));

/// Choose how a plan's intake is tracked (by distance or time) and the
/// interval between fuel points. Persists onto the plan, which unlocks the
/// timeline. Collapses to a summary once set, with a Change button to re-edit.
export function IntakeSection({ plan }: { plan: Plan }) {
  const { t } = useTranslation();
  const [mode, setMode] = useState<PlanType | null>(plan.planType);
  const [interval, setInterval] = useState(
    plan.intakeInterval ?? defaultInterval(plan.planType ?? 'distance'),
  );
  const [editing, setEditing] = useState(plan.planType === null);

  const isDistance = mode === 'distance';

  const save = async () => {
    if (!mode) return;
    await setIntakeTracking({ id: plan.id, planType: mode, interval });
    setEditing(false);
  };

  if (!editing && plan.planType) {
    const every = plan.intakeInterval ?? 0;
    const summary =
      plan.planType === 'distance'
        ? t('plans.intakeEveryKm', { n: num(every) })
        : t('plans.intakeEveryMin', { n: num(every) });
    return (
      <Card>
        <Card.Content>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <Text variant="titleMedium" style={{ flex: 1 }}>
              {t('plans.intakeTracking')}
            </Text>
            <Button onPress={() => setEditing(true)}>{t('common.change')}</Button>
          </View>
          <Text>{summary}</Text>
        </Card.Content>
      </Card>
    );
  }

  return (
    <Card>
      <Card.Content style={{ gap: 12 }}>
        <Text>{t('plans.intakeQuestion')}</Text>
        <SegmentedButtons
          value={mode ?? ''}
          onValueChange={(v) => {
            const m = v as PlanType;
            setMode(m);
            setInterval(defaultInterval(m));
          }}
          buttons={[
            {
              value: 'distance',
              label: t('plans.intakeByDistance'),
              icon: 'ruler',
            },
            { value: 'duration', label: t('plans.intakeByTime'), icon: 'timer-outline' },
          ]}
        />
        {mode && (
          <SliderInput
            label={t(isDistance ? 'plans.intervalDistance' : 'plans.intervalDuration')}
            value={interval}
            min={isDistance ? 1 : 5}
            max={isDistance ? 10 : 60}
            step={isDistance ? 1 : 5}
            onChange={setInterval}
          />
        )}
        <Button mode="contained" disabled={!mode} onPress={save}>
          {t('common.save')}
        </Button>
      </Card.Content>
    </Card>
  );
}
