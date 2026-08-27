import 'package:flutter/material.dart';

import 'package:eatrun/l10n/app_localizations.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
