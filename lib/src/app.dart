import 'package:flutter/material.dart';

import 'core/router/app_router.dart';

class EatRunApp extends StatelessWidget {
  const EatRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eatRUN',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
