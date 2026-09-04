import { useMigrations } from 'drizzle-orm/expo-sqlite/migrator';
import type { ReactNode } from 'react';
import {
  DarkTheme,
  DefaultTheme,
  Stack,
  ThemeProvider,
} from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme, View } from 'react-native';
import { ActivityIndicator, PaperProvider, Text } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { db } from '@/core/db/client';
import { darkTheme, lightTheme } from '@/core/theme/theme';
import migrations from '../../drizzle/migrations';

export default function RootLayout() {
  const scheme = useColorScheme();
  const dark = scheme === 'dark';
  const paperTheme = dark ? darkTheme : lightTheme;

  // Map Paper's MD3 palette into React Navigation's theme so headers, the tab
  // bar, the status-bar area and screen backgrounds all follow the scheme.
  const navBase = dark ? DarkTheme : DefaultTheme;
  const navTheme = {
    ...navBase,
    colors: {
      ...navBase.colors,
      primary: paperTheme.colors.primary,
      background: paperTheme.colors.background,
      card: paperTheme.colors.surface,
      text: paperTheme.colors.onSurface,
      border: paperTheme.colors.outlineVariant,
    },
  };

  const { success, error } = useMigrations(db, migrations);

  return (
    <SafeAreaProvider>
      <PaperProvider theme={paperTheme}>
        <ThemeProvider value={navTheme}>
          <StatusBar style={dark ? 'light' : 'dark'} />
          {error ? (
            <Fill bg={paperTheme.colors.background}>
              <Text>Database error: {error.message}</Text>
            </Fill>
          ) : !success ? (
            <Fill bg={paperTheme.colors.background}>
              <ActivityIndicator />
            </Fill>
          ) : (
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="(tabs)" />
            </Stack>
          )}
        </ThemeProvider>
      </PaperProvider>
    </SafeAreaProvider>
  );
}

function Fill({ bg, children }: { bg: string; children: ReactNode }) {
  return (
    <View
      style={{
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: bg,
      }}
    >
      {children}
    </View>
  );
}
