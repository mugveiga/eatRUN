import 'package:flutter/material.dart';

import 'package:eatrun/l10n/app_localizations.dart';

import 'core/router/app_router.dart';

class EatRunApp extends StatelessWidget {
  const EatRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eatRUN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
