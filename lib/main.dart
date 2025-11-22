// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'core/settings/app_settings.dart';
import 'presentation/screens/splash_screen.dart'; // 👈 SplashScreen'i kullanacağız

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.I.load();

  runApp(
    Phoenix(
      child: ChangeNotifierProvider.value(
        value: AppSettings.I,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EczSearch',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A885),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A885),
          brightness: Brightness.dark,
        ),
      ),

      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // 👇 Uygulama açılış ekranı
      home: const SplashScreen(),
      // Eğer direkt ana ekrana gitmek istersen:
      // home: const RootShell(),
    );
  }
}
