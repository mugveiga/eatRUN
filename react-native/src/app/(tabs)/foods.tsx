import { View } from 'react-native';
import { Text } from 'react-native-paper';

export default function FoodsScreen() {
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text variant="titleLarge">Foods</Text>
      <Text variant="bodyMedium">Coming next: your food library.</Text>
    </View>
  );
}
