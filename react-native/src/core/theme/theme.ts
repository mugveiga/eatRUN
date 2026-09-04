import { MD3DarkTheme, MD3LightTheme } from 'react-native-paper';

// eatRUN's deep-orange brand seed (matches the Flutter build).
const seed = '#FF5722';

export const lightTheme = {
  ...MD3LightTheme,
  colors: { ...MD3LightTheme.colors, primary: seed },
};

export const darkTheme = {
  ...MD3DarkTheme,
  colors: { ...MD3DarkTheme.colors, primary: seed },
};

export type AppTheme = typeof lightTheme;
