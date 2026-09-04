import * as ImagePicker from 'expo-image-picker';
import { Image } from 'expo-image';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Alert,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  View,
} from 'react-native';
import {
  ActivityIndicator,
  Appbar,
  Button,
  HelperText,
  Icon,
  TextInput,
  useTheme,
} from 'react-native-paper';

import { findFood, saveFood } from '../data/foods-repository';

const onlyDigits = (s: string) => s.replace(/[^0-9]/g, '');

// Keep digits and at most one decimal point.
const decimalStr = (s: string) => {
  const c = s.replace(/[^0-9.]/g, '');
  const i = c.indexOf('.');
  return i === -1 ? c : c.slice(0, i + 1) + c.slice(i + 1).replace(/\./g, '');
};

const capInt = (s: string, max: number) =>
  parseInt(s || '0', 10) > max ? String(max) : s;
const capFloat = (s: string, max: number) =>
  parseFloat(s || '0') > max ? String(max) : s;

const formatSalt = (grams: number) => {
  let s = grams.toFixed(2);
  if (s.includes('.')) s = s.replace(/0+$/, '').replace(/\.$/, '');
  return s;
};

// Realistic per-serving caps. 1 g sodium = 2.5 g salt → sodium_mg = salt_g × 400.
const MAX_CARBS = 1000;
const MAX_CAFFEINE = 1000;
const MAX_SODIUM_MG = 10000;
const SODIUM_PER_SALT_G = 400;
const MAX_SALT_G = MAX_SODIUM_MG / SODIUM_PER_SALT_G;

export function FoodFormScreen() {
  const router = useRouter();
  const theme = useTheme();
  const { t } = useTranslation();
  const { id } = useLocalSearchParams<{ id?: string }>();
  const isEditing = !!id;

  const [loaded, setLoaded] = useState(!isEditing);
  const [name, setName] = useState('');
  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [carbs, setCarbs] = useState('');
  const [sodium, setSodium] = useState('');
  const [caffeine, setCaffeine] = useState('');
  const [notes, setNotes] = useState('');
  const [nameError, setNameError] = useState(false);
  // Sodium field can accept salt (g) instead; we always store sodium (mg).
  const [saltMode, setSaltMode] = useState(false);

  useEffect(() => {
    if (!isEditing) return;
    (async () => {
      const f = await findFood(id!);
      if (f) {
        setName(f.name);
        setPhotoUri(f.photoUri);
        setCarbs(String(f.carbsGrams));
        setSodium(String(f.sodiumMg));
        setCaffeine(String(f.caffeineMg));
        setNotes(f.notes ?? '');
      }
      setLoaded(true);
    })();
  }, [id, isEditing]);

  async function launch(source: 'camera' | 'library') {
    const perm =
      source === 'camera'
        ? await ImagePicker.requestCameraPermissionsAsync()
        : await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) return;
    const result =
      source === 'camera'
        ? await ImagePicker.launchCameraAsync({ quality: 0.5 })
        : await ImagePicker.launchImageLibraryAsync({ quality: 0.5 });
    if (!result.canceled) setPhotoUri(result.assets[0].uri);
  }

  function pickPhoto() {
    Alert.alert(t('foods.photo'), undefined, [
      { text: t('foods.takePhoto'), onPress: () => launch('camera') },
      { text: t('foods.chooseFromGallery'), onPress: () => launch('library') },
      { text: t('common.cancel'), style: 'cancel' },
    ]);
  }

  function toggleSalt() {
    const cur = parseFloat(sodium);
    if (!isNaN(cur)) {
      setSodium(
        saltMode
          ? String(Math.round(cur * SODIUM_PER_SALT_G)) // salt g → sodium mg
          : formatSalt(cur / SODIUM_PER_SALT_G), // sodium mg → salt g
      );
    }
    setSaltMode((m) => !m);
  }

  async function save() {
    if (!name.trim()) {
      setNameError(true);
      return;
    }
    const sodiumMg = saltMode
      ? Math.round((parseFloat(sodium) || 0) * SODIUM_PER_SALT_G)
      : parseInt(sodium || '0', 10);
    await saveFood({
      id,
      name: name.trim(),
      photoUri,
      carbsGrams: parseInt(carbs || '0', 10),
      sodiumMg,
      caffeineMg: parseInt(caffeine || '0', 10),
      notes: notes.trim() || null,
    });
    router.back();
  }

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
        <Appbar.Content title={isEditing ? t('foods.edit') : t('foods.new')} />
      </Appbar.Header>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView
          contentContainerStyle={{ padding: 16, gap: 12, paddingBottom: 48 }}
          keyboardShouldPersistTaps="handled"
        >
          <Pressable onPress={pickPhoto}>
            <View
              style={{
                aspectRatio: 16 / 9,
                borderRadius: 16,
                overflow: 'hidden',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: theme.colors.surfaceVariant,
              }}
            >
              {photoUri ? (
                <Image
                  source={{ uri: photoUri }}
                  style={{ width: '100%', height: '100%' }}
                  contentFit="contain"
                />
              ) : (
                <Icon source="camera-plus-outline" size={32} />
              )}
            </View>
          </Pressable>

          <View>
            <TextInput
              label={t('foods.name')}
              mode="outlined"
              value={name}
              error={nameError}
              onChangeText={(text) => {
                setName(text);
                setNameError(false);
              }}
            />
            {nameError && (
              <HelperText type="error">{t('common.required')}</HelperText>
            )}
          </View>

          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TextInput
              style={{ flex: 1 }}
              label={t('foods.carbs')}
              mode="outlined"
              keyboardType="number-pad"
              right={<TextInput.Affix text="g" />}
              value={carbs}
              onChangeText={(text) =>
                setCarbs(capInt(onlyDigits(text), MAX_CARBS))
              }
            />
            <TextInput
              style={{ flex: 1 }}
              label={saltMode ? t('foods.salt') : t('foods.sodium')}
              mode="outlined"
              keyboardType={saltMode ? 'decimal-pad' : 'number-pad'}
              right={<TextInput.Affix text={saltMode ? 'g' : 'mg'} />}
              value={sodium}
              onChangeText={(text) =>
                setSodium(
                  saltMode
                    ? capFloat(decimalStr(text), MAX_SALT_G)
                    : capInt(onlyDigits(text), MAX_SODIUM_MG),
                )
              }
            />
            <TextInput
              style={{ flex: 1 }}
              label={t('foods.caffeine')}
              mode="outlined"
              keyboardType="number-pad"
              right={<TextInput.Affix text="mg" />}
              value={caffeine}
              onChangeText={(text) =>
                setCaffeine(capInt(onlyDigits(text), MAX_CAFFEINE))
              }
            />
          </View>
          <Button
            mode="text"
            compact
            icon="swap-horizontal"
            onPress={toggleSalt}
            style={{ alignSelf: 'flex-start' }}
          >
            {saltMode ? t('foods.enterAsSodium') : t('foods.enterAsSalt')}
          </Button>

          <TextInput
            label={t('foods.notes')}
            mode="outlined"
            multiline
            style={{ minHeight: 110 }}
            value={notes}
            onChangeText={setNotes}
          />
          <Button mode="contained" onPress={save} style={{ marginTop: 8 }}>
            {t('common.save')}
          </Button>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
