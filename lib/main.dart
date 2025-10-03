// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Services/pos_service.dart';
import 'Views/login_screen.dart';
import 'app_config.dart';

const Color seed = Colors.deepOrange;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfig>(
      future: AppConfig.load(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return ChangeNotifierProvider(
          create: (_) => PosService(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mpepo POS',
            themeMode: ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: seed,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.orange.withAlpha((0.06 * 255).round()),
              ),
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: seed,
                foregroundColor: Colors.white,
              ),
            ),
            home: const LoginScreen(),
          ),
        );
      },
    );
  }
}
