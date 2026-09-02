import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/locale_provider.dart';
import 'services/ads_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocaleProvider.initPreferences();

  AdsService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleProvider.localeNotifier,
      builder: (context, locale, child) {
        final isArabic = locale.languageCode == 'ar';

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Watermark Pro',
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
