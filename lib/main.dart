// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Services/pos_service.dart';
import 'Views/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PosService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Now, MyApp and all its children (including MaterialApp and its pages)
    // are below the ChangeNotifierProvider in the widget tree.
    return MaterialApp(
      title: 'Mpepo Kitchen POS',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
