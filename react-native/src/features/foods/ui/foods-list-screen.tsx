import { useRouter } from 'expo-router';
import { FlatList, View } from 'react-native';
import {
  Avatar,
  Divider,
  FAB,
  IconButton,
  List,
  Text,
} from 'react-native-paper';

import { deleteFood } from '../data/foods-repository';
import { useFoods } from '../data/use-foods';

export function FoodsListScreen() {
  const router = useRouter();
  const { data: items } = useFoods();

  return (
    <View style={{ flex: 1 }}>
      {items.length === 0 ? (
        <View
          style={{
            flex: 1,
            alignItems: 'center',
            justifyContent: 'center',
            padding: 32,
          }}
        >
          <Text variant="bodyLarge" style={{ textAlign: 'center' }}>
            No foods yet.{'\n'}Add the gels, drinks and snacks you fuel with.
          </Text>
        </View>
      ) : (
        <FlatList
          data={items}
          keyExtractor={(f) => f.id}
          ItemSeparatorComponent={Divider}
          contentContainerStyle={{ paddingBottom: 96 }}
          renderItem={({ item }) => (
            <List.Item
              title={item.name}
              description={`${item.carbsGrams}g carbs · ${item.sodiumMg}mg sodium · ${item.caffeineMg}mg caffeine`}
              left={(props) =>
                item.photoUri ? (
                  <Avatar.Image
                    {...props}
                    size={40}
                    source={{ uri: item.photoUri }}
                  />
                ) : (
                  <Avatar.Icon {...props} size={40} icon="food-apple" />
                )
              }
              right={(props) => (
                <IconButton
                  {...props}
                  icon="delete-outline"
                  onPress={() => deleteFood(item.id)}
                />
              )}
              onPress={() =>
                router.push({ pathname: '/foods/[id]', params: { id: item.id } })
              }
            />
          )}
        />
      )}
      <FAB
        icon="plus"
        label="Add food"
        style={{ position: 'absolute', right: 16, bottom: 16 }}
        onPress={() => router.push('/foods/new')}
      />
    </View>
  );
}
