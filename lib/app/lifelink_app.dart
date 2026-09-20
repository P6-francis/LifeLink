import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';

class LifeLinkApp extends StatelessWidget {
  const LifeLinkApp({super.key});

  static const red = Color(0xffd9283b);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLink',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: red),
        scaffoldBackgroundColor: const Color(0xfff8f8fa),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff24242a),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe1e1e5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffe1e1e5)),
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
