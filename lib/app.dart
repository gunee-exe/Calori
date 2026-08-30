/// The app shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/home/providers.dart';
import 'features/shell/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

class CaloriApp extends StatelessWidget {
  const CaloriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calori',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _Root(),
    );
  }
}

/// Routes on whether a profile exists.
///
/// Reads the profile *stream*, so completing onboarding moves the user to Home
/// as a consequence of the row being written rather than of a navigation call.
/// There is then no way to reach Home without a saved goal, which is what makes
/// the safety rules unbypassable rather than merely first in the sequence.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return switch (profile) {
      AsyncData(:final value) =>
        value == null ? const OnboardingScreen() : const AppShell(),

      // Opening the diary copies no asset and is fast, but it is still I/O.
      // A blank themed screen avoids a spinner that would flash for one frame.
      AsyncLoading() => const _Splash(),

      _ => const _Splash(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.bg);
}
