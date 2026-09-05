import { zodResolver } from '@hookform/resolvers/zod';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { Control, Controller, useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { KeyboardAvoidingView, Platform, ScrollView, View } from 'react-native';
import {
  ActivityIndicator,
  Appbar,
  Button,
  HelperText,
  SegmentedButtons,
  Text,
  TextInput,
  useTheme,
} from 'react-native-paper';
import { z } from 'zod';

import { SliderInput } from '@/core/widgets/slider-input';
import { findPlan, savePlan } from '../data/plans-repository';
import {
  clamp,
  durationFromPaceOrSpeed,
  durationScaledByDistance,
  formatPace,
  maskPace,
  paceOrSpeed,
  parsePace,
} from '../logic/workout-sync';

const DUR_MIN = 30;
const DUR_MAX = 600;

function tomorrow(): Date {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  return d;
}

const schema = z.object({
  name: z.string().trim().min(1),
  date: z.date(),
  activityType: z.enum(['run', 'bike']),
  distanceKm: z.number().positive(),
  durationMinutes: z.number().int().positive(),
  targetCarbsPerHour: z.number().min(0),
  targetSodiumPerHour: z.number().min(0),
  targetCaffeinePerHour: z.number().min(0),
  comments: z.string(),
});
type PlanForm = z.infer<typeof schema>;
type NumericField =
  | 'distanceKm'
  | 'durationMinutes'
  | 'targetCarbsPerHour'
  | 'targetSodiumPerHour'
  | 'targetCaffeinePerHour';

function NumberField(props: {
  control: Control<PlanForm>;
  name: NumericField;
  label: string;
  decimals?: boolean;
  max?: number;
  affix?: string;
}) {
  const { control, name, label, decimals = true, max, affix } = props;
  return (
    <Controller
      control={control}
      name={name}
      render={({ field: { value, onChange } }) => (
        <TextInput
          style={{ flex: 1 }}
          mode="outlined"
          label={label}
          keyboardType={decimals ? 'decimal-pad' : 'number-pad'}
          right={affix ? <TextInput.Affix text={affix} /> : undefined}
          value={String(value)}
          onChangeText={(text) => {
            const clean = text.replace(decimals ? /[^0-9.]/g : /[^0-9]/g, '');
            const n = clean === '' ? 0 : Number(clean);
            onChange(max != null ? Math.min(n, max) : n);
          }}
        />
      )}
    />
  );
}

export function PlanFormScreen() {
  const router = useRouter();
  const theme = useTheme();
  const { t } = useTranslation();
  const { id } = useLocalSearchParams<{ id?: string }>();
  const isEditing = !!id;

  const [loaded, setLoaded] = useState(!isEditing);
  const [showDate, setShowDate] = useState(false);

  const { control, handleSubmit, reset, formState, watch, setValue } =
    useForm<PlanForm>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: t('plans.defaultName'),
      date: tomorrow(),
      activityType: 'run',
      distanceKm: 10,
      durationMinutes: 60,
      targetCarbsPerHour: 60,
      targetSodiumPerHour: 500,
      targetCaffeinePerHour: 0,
      comments: '',
    },
  });

  useEffect(() => {
    if (!isEditing) return;
    (async () => {
      const p = await findPlan(id!);
      if (p) {
        reset({
          name: p.name,
          date: p.date,
          activityType: p.activityType,
          distanceKm: p.distanceKm,
          durationMinutes: p.durationMinutes,
          targetCarbsPerHour: p.targetCarbsPerHour,
          targetSodiumPerHour: p.targetSodiumPerHour,
          targetCaffeinePerHour: p.targetCaffeinePerHour,
          comments: p.comments ?? '',
        });
      }
      setLoaded(true);
    })();
  }, [id, isEditing, reset]);

  const onSubmit = async (data: PlanForm) => {
    await savePlan({
      id,
      name: data.name.trim(),
      date: data.date,
      activityType: data.activityType,
      distanceKm: data.distanceKm,
      durationMinutes: data.durationMinutes,
      targetCarbsPerHour: data.targetCarbsPerHour,
      targetSodiumPerHour: data.targetSodiumPerHour,
      targetCaffeinePerHour: data.targetCaffeinePerHour,
      comments: data.comments.trim() || null,
    });
    router.back();
  };

  // Distance is the anchor; editing it holds pace and rescales duration.
  // Editing pace/speed or duration recomputes the other, staying consistent.
  const distanceKm = watch('distanceKm');
  const durationMinutes = watch('durationMinutes');
  const activityType = watch('activityType');
  const isRun = activityType === 'run';
  const paceValue = paceOrSpeed(distanceKm, durationMinutes, activityType);

  const onDistance = (d: number) => {
    const dur = clamp(
      durationScaledByDistance(distanceKm, durationMinutes, d),
      DUR_MIN,
      DUR_MAX,
    );
    setValue('distanceKm', d);
    setValue('durationMinutes', Math.round(dur));
  };
  const onDuration = (dur: number) => setValue('durationMinutes', Math.round(dur));
  const onPace = (v: number) => {
    const dur = clamp(
      durationFromPaceOrSpeed(distanceKm, v, activityType),
      DUR_MIN,
      DUR_MAX,
    );
    setValue('durationMinutes', Math.round(dur));
  };

  if (!loaded) {
    return (
      <View style={{ flex: 1, justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: theme.colors.background }}>
      <Appbar.Header>
        <Appbar.BackAction onPress={() => router.back()} />
        <Appbar.Content title={isEditing ? t('plans.edit') : t('plans.new')} />
      </Appbar.Header>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={{ padding: 16, gap: 12, paddingBottom: 48 }}
          keyboardShouldPersistTaps="handled"
        >
          <Controller
            control={control}
            name="name"
            render={({ field: { value, onChange } }) => (
              <View>
                <TextInput
                  label={t('plans.name')}
                  mode="outlined"
                  value={value}
                  error={!!formState.errors.name}
                  onChangeText={onChange}
                />
                {formState.errors.name && (
                  <HelperText type="error">{t('common.required')}</HelperText>
                )}
              </View>
            )}
          />

          <Controller
            control={control}
            name="date"
            render={({ field: { value, onChange } }) => (
              <View>
                <Button
                  mode="outlined"
                  icon="calendar"
                  onPress={() => setShowDate(true)}
                >
                  {`${t('plans.date')}: ${value.toLocaleDateString()}`}
                </Button>
                {showDate && (
                  <DateTimePicker
                    value={value}
                    mode="date"
                    onValueChange={(_, d) => {
                      setShowDate(false);
                      onChange(d);
                    }}
                    onDismiss={() => setShowDate(false)}
                  />
                )}
              </View>
            )}
          />

          <Controller
            control={control}
            name="activityType"
            render={({ field: { value, onChange } }) => (
              <SegmentedButtons
                value={value}
                onValueChange={onChange}
                buttons={[
                  { value: 'run', label: t('plans.activityRun'), icon: 'run' },
                  { value: 'bike', label: t('plans.activityBike'), icon: 'bike' },
                ]}
              />
            )}
          />

          <SliderInput
            label={t('plans.distance')}
            value={distanceKm}
            min={5}
            max={100}
            step={1}
            onChange={onDistance}
          />
          <SliderInput
            label={t('plans.duration')}
            value={durationMinutes}
            min={DUR_MIN}
            max={DUR_MAX}
            step={5}
            onChange={onDuration}
          />
          <SliderInput
            label={isRun ? t('plans.pace') : t('plans.speed')}
            value={paceValue}
            min={isRun ? 3 : 10}
            max={isRun ? 12 : 50}
            step={isRun ? 5 / 60 : 1}
            onChange={onPace}
            format={isRun ? formatPace : undefined}
            parse={isRun ? parsePace : undefined}
            mask={isRun ? maskPace : undefined}
          />

          <Text variant="titleMedium" style={{ marginTop: 8 }}>
            {t('plans.targetsPerHour')}
          </Text>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <NumberField
              control={control}
              name="targetCarbsPerHour"
              label={t('plans.carbs')}
              affix="g/h"
              max={120}
            />
            <NumberField
              control={control}
              name="targetSodiumPerHour"
              label={t('plans.sodium')}
              affix="mg/h"
              max={2000}
            />
            <NumberField
              control={control}
              name="targetCaffeinePerHour"
              label={t('plans.caffeine')}
              affix="mg/h"
              max={200}
            />
          </View>

          <Controller
            control={control}
            name="comments"
            render={({ field: { value, onChange } }) => (
              <TextInput
                label={t('plans.comments')}
                mode="outlined"
                multiline
                style={{ minHeight: 90 }}
                value={value}
                onChangeText={onChange}
              />
            )}
          />

          <Button
            mode="contained"
            onPress={handleSubmit(onSubmit)}
            style={{ marginTop: 8 }}
          >
            {t('common.save')}
          </Button>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
