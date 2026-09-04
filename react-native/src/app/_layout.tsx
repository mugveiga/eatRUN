import { useMigrations } from 'drizzle-orm/expo-sqlite/migrator';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme, View } from 'react-native';
import { ActivityIndicator, PaperProvider, Text } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { db } from '@/core/db/client';
import { darkTheme, lightTheme } from '@/core/theme/theme';
import migrations from '../../drizzle/migrations';

function Centered({ children }: { children: React.ReactNode }) {
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      {children}
    </View>
  );
}

export default function RootLayout() {
  const scheme = useColorScheme();
  const theme = scheme === 'dark' ? darkTheme : lightTheme;
  const { success, error } = useMigrations(db, migrations);

  return (
    <SafeAreaProvider>
      <PaperProvider theme={theme}>
        <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
        {error ? (
          <Centered>
            <Text>Database error: {error.message}</Text>
          </Centered>
        ) : !success ? (
          <Centered>
            <ActivityIndicator />
          </Centered>
        ) : (
          <Stack screenOptions={{ headerShown: false }}>
            <Stack.Screen name="(tabs)" />
          </Stack>
        )}
      </PaperProvider>
    </SafeAreaProvider>
  );
}
