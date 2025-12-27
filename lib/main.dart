import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_theme.dart';
import 'home/home_page.dart';
import 'home/group_store.dart';

void main() {
  usePathUrlStrategy();
  runApp(ModularApp(module: AppModule(), child: AppWidget()));
}

class AppModule extends Module {
  @override
  void routes(r) {
    r.module(
      '/',
      module: HomeModule(),
      transition: TransitionType.noTransition,
    );
  }
}

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Modular.setInitialRoute('/$defaultGroup');
    Modular.to.addListener(() {
      debugPrint('Navigate: ${Modular.to.path}');
      debugPrint('History: ${Modular.to.navigateHistory.map((e) => e.name)}');
    });

    return MaterialApp.router(
      title: 'Elaine',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routeInformationParser: Modular.routeInformationParser,
      routerDelegate: Modular.routerDelegate,
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'HK',
        ),
      ],
    );
  }
}
