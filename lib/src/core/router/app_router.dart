import 'package:go_router/go_router.dart';

import '../../features/foods/presentation/food_form_screen.dart';
import '../../features/foods/presentation/foods_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/foods',
  routes: [
    GoRoute(
      path: '/foods',
      builder: (context, state) => const FoodsListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const FoodFormScreen(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              FoodFormScreen(foodId: state.pathParameters['id']),
        ),
      ],
    ),
  ],
);
