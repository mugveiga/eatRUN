import { View } from 'react-native';
import { Text } from 'react-native-paper';

export default function PlansScreen() {
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text variant="titleLarge">Plans</Text>
      <Text variant="bodyMedium">Coming next: your fueling plans.</Text>
    </View>
  );
}
