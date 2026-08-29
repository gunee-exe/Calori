import 'package:flutter/material.dart';

void main() => runApp(const CaloriApp());

/// Placeholder shell. Phase 1 replaces this with the themed app in `app.dart`,
/// driven by the tokens extracted from the Bright Blue prototype.
class CaloriApp extends StatelessWidget {
  const CaloriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Calori',
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: Color(0xFFEAEFF9)),
    );
  }
}
