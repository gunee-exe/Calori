/// The app shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class CaloriApp extends ConsumerWidget {
  const CaloriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Calori',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
