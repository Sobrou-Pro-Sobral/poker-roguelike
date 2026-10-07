import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PokerRogueApp());
}

class PokerRogueApp extends StatelessWidget {
  const PokerRogueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Roguelike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE51B2B),
          primary: const Color(0xFFE51B2B),
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
