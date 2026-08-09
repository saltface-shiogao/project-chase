import 'package:flutter/material.dart';

import 'views/game_page.dart';

void main() {
  runApp(const CityChaseApp());
}

class CityChaseApp extends StatelessWidget {
  const CityChaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'シティチェイス',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}
