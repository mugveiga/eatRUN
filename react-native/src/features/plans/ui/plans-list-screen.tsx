import { Link } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { FlatList, View } from 'react-native';
import { Avatar, Divider, FAB, IconButton, List, Text } from 'react-native-paper';

import { deletePlan } from '../data/plans-repository';
import { usePlans } from '../data/use-plans';

export function PlansListScreen() {
  const { t } = useTranslation();
  const { data: items } = usePlans();

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
            {t('plans.empty')}
          </Text>
        </View>
      ) : (
        <FlatList
          data={items}
          keyExtractor={(p) => p.id}
          ItemSeparatorComponent={Divider}
          contentContainerStyle={{ paddingBottom: 96 }}
          renderItem={({ item }) => (
            <Link
              href={{ pathname: '/plans/[id]', params: { id: item.id } }}
              asChild
            >
              <List.Item
                title={item.name}
                description={`${item.date.toLocaleDateString()} · ${t(
                  'plans.distanceValue',
                  { km: String(item.distanceKm) },
                )}`}
                left={(props) => (
                  <Avatar.Icon
                    {...props}
                    size={40}
                    icon={
                      item.activityType === 'bike'
                        ? 'bike'
                        : 'run'
                    }
                  />
                )}
                right={(props) => (
                  <IconButton
                    {...props}
                    icon="delete-outline"
                    onPress={() => deletePlan(item.id)}
                  />
                )}
              />
            </Link>
          )}
        />
      )}
      <Link href="/plans/new" asChild>
        <FAB
          icon="plus"
          label={t('plans.addPlan')}
          style={{ position: 'absolute', right: 16, bottom: 16 }}
        />
      </Link>
    </View>
  );
}
