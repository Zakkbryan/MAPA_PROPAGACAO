import 'package:flutter/material.dart';
import 'presentation/screens/home_map_screen.dart';

void main() {
  runApp(const HfPropagationApp());
}

class HfPropagationApp extends StatelessWidget {
  const HfPropagationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa de Propagação HF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeMapScreen(),
    );
  }
}
