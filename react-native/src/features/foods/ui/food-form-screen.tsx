import * as ImagePicker from 'expo-image-picker';
import { Image } from 'expo-image';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useState } from 'react';
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

export function FoodFormScreen() {
  const router = useRouter();
  const theme = useTheme();
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
    Alert.alert('Photo', undefined, [
      { text: 'Take photo', onPress: () => launch('camera') },
      { text: 'Choose from gallery', onPress: () => launch('library') },
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  async function save() {
    if (!name.trim()) {
      setNameError(true);
      return;
    }
    await saveFood({
      id,
      name: name.trim(),
      photoUri,
      carbsGrams: parseInt(carbs || '0', 10),
      sodiumMg: parseInt(sodium || '0', 10),
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
        <Appbar.Content title={isEditing ? 'Edit food' : 'New food'} />
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
              label="Name"
              mode="outlined"
              value={name}
              error={nameError}
              onChangeText={(t) => {
                setName(t);
                setNameError(false);
              }}
            />
            {nameError && <HelperText type="error">Required</HelperText>}
          </View>

          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TextInput
              style={{ flex: 1 }}
              label="Carbs"
              mode="outlined"
              keyboardType="number-pad"
              right={<TextInput.Affix text="g" />}
              value={carbs}
              onChangeText={(t) => setCarbs(onlyDigits(t))}
            />
            <TextInput
              style={{ flex: 1 }}
              label="Sodium"
              mode="outlined"
              keyboardType="number-pad"
              right={<TextInput.Affix text="mg" />}
              value={sodium}
              onChangeText={(t) => setSodium(onlyDigits(t))}
            />
            <TextInput
              style={{ flex: 1 }}
              label="Caffeine"
              mode="outlined"
              keyboardType="number-pad"
              right={<TextInput.Affix text="mg" />}
              value={caffeine}
              onChangeText={(t) => setCaffeine(onlyDigits(t))}
            />
          </View>

          <TextInput
            label="Notes"
            mode="outlined"
            multiline
            style={{ minHeight: 110 }}
            value={notes}
            onChangeText={setNotes}
          />
          <Button mode="contained" onPress={save} style={{ marginTop: 8 }}>
            Save
          </Button>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
