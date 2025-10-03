// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/pos_service.dart';
import 'views/login_screen.dart';

const Color seed = Colors.deepOrange;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PosService _posService;

  @override
  void initState() {
    super.initState();
    _posService = PosService();
    // Attempt to sync pending orders when the app starts.
    _posService.syncPendingOrders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _posService,
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
          appBarTheme: const AppBarTheme(centerTitle: true),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.orange.withOpacity(0.06),
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
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
