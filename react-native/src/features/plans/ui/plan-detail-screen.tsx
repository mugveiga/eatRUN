import { Link, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ScrollView, View } from 'react-native';
import { ActivityIndicator, Appbar, Card, Text } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { usePlan } from '../data/use-plans';
import { IntakeSection } from './intake-section';
import { ScoreSection } from './score-section';
import { TimelineSection } from './timeline-section';

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View style={{ flexDirection: 'row', paddingVertical: 4 }}>
      <Text style={{ flex: 1 }}>{label}</Text>
      <Text variant="titleMedium">{value}</Text>
    </View>
  );
}

export function PlanDetailScreen() {
  const router = useRouter();
  const { t } = useTranslation();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data } = usePlan(id);
  const plan = data.at(0);
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1 }}>
      <Appbar.Header>
        <Appbar.BackAction onPress={() => router.back()} />
        <Appbar.Content title={plan?.name ?? ''} />
        <Link href={{ pathname: '/plans/[id]/edit', params: { id } }} asChild>
          <Appbar.Action icon="pencil" />
        </Link>
      </Appbar.Header>
      {!plan ? (
        <View style={{ flex: 1, justifyContent: 'center' }}>
          <ActivityIndicator />
        </View>
      ) : (
        <ScrollView
          contentContainerStyle={{
            padding: 16,
            gap: 12,
            paddingBottom: insets.bottom + 24,
          }}
        >
          <Card>
            <Card.Content>
              <Row label={t('plans.date')} value={plan.date.toLocaleDateString()} />
              <Row
                label={t('plans.activity')}
                value={
                  plan.activityType === 'bike'
                    ? t('plans.activityBike')
                    : t('plans.activityRun')
                }
              />
              <Row label={t('plans.distance')} value={String(plan.distanceKm)} />
              <Row
                label={t('plans.duration')}
                value={String(plan.durationMinutes)}
              />
            </Card.Content>
          </Card>
          <Card>
            <Card.Content>
              <Text variant="titleMedium">{t('plans.targetsPerHour')}</Text>
              <Row
                label={t('plans.targetCarbs')}
                value={String(plan.targetCarbsPerHour)}
              />
              <Row
                label={t('plans.targetSodium')}
                value={String(plan.targetSodiumPerHour)}
              />
              <Row
                label={t('plans.targetCaffeine')}
                value={String(plan.targetCaffeinePerHour)}
              />
            </Card.Content>
          </Card>
          <IntakeSection plan={plan} />
          {plan.planType && (
            <>
              <TimelineSection plan={plan} />
              <ScoreSection plan={plan} />
            </>
          )}
        </ScrollView>
      )}
    </View>
  );
}
