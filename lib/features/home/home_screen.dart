/// Today (UC-07).
///
/// Calories first, protein prominent, carbs and fat secondary — the order
/// `01-concept.md` sets out. Over target draws a second dim lap on the ring and
/// changes the caption; nothing anywhere turns red.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_label.dart';
import '../../domain/models/day_key.dart';
import '../../domain/models/entry.dart';
import '../../domain/repositories/diary_repository.dart';
import '../photo/capture_sheet.dart';
import 'providers.dart';
import 'widgets/date_strip.dart';
import 'widgets/meal_card.dart';
import 'widgets/protein_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = ref.watch(selectedDayProvider);
    final profile = ref.watch(profileProvider).value;
    final totals = ref.watch(totalsForSelectedDayProvider).value;
    final entries = ref.watch(entriesForSelectedDayProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Room at the bottom for the floating add button, which otherwise
          // sits on top of the last card and covers its figures.
          padding: AppLayout.screenPadding.add(
            const EdgeInsets.only(bottom: AppLayout.fabSize + 24),
          ),
          children: [
            const DateStrip(),
            const SizedBox(height: 14),
            Text(formatDayKeyLong(dayKey), style: AppType.secondary),

            const SizedBox(height: 12),
            _Ring(totals: totals, hasProfile: profile != null),

            const SizedBox(height: 10),
            _CalorieLine(totals: totals, profile: profile),

            const SizedBox(height: 14),
            if (profile != null && totals != null)
              ProteinCard(totals: totals, profile: profile),

            const SizedBox(height: 26),
            SectionLabel(
              dayKey == DayKey.today() ? 'Today' : formatDayKeyShort(dayKey),
            ),
            const SizedBox(height: 12),
            _Meals(entries: entries ?? const []),
          ],
        ),
      ),
      floatingActionButton: _AddButton(dayKey: dayKey),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.totals, required this.hasProfile});

  final DayTotals? totals;
  final bool hasProfile;

  @override
  Widget build(BuildContext context) {
    // Before a goal exists there is no denominator, so a percentage would be
    // meaningless. The ring still draws its track, which keeps the layout
    // stable rather than making the screen jump once onboarding completes.
    final showPercent = hasProfile && totals != null && totals!.targetKcal > 0;

    return Center(
      child: CalorieRing(
        progress: showPercent ? totals!.progress : 0,
        center: showPercent
            ? Text(
                '${(totals!.progress * 100).round()}%',
                style: AppType.ringPercent,
              )
            : const Text('—', style: AppType.ringPercent),
      ),
    );
  }
}

class _CalorieLine extends StatelessWidget {
  const _CalorieLine({required this.totals, required this.profile});

  final DayTotals? totals;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No goal set yet', style: AppType.bodyStrong),
          SizedBox(height: 2),
          Text(
            'Set one to see how your day compares.',
            style: AppType.secondary,
          ),
        ],
      );
    }

    final consumed = totals?.consumed.kcal ?? 0;
    final target = profile!.dailyKcal;
    final over = consumed > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatKcal(consumed)} / ${formatKcal(target.toDouble())} kcal',
          style: AppType.bodyStrong,
        ),
        const SizedBox(height: 2),
        Text(
          // Never a negative number. A minus sign in front of a calorie count
          // reads as a penalty, which is the tone this app refuses.
          consumed == 0
              ? 'nothing logged yet'
              : over
              ? 'over today'
              : 'left today',
          style: AppType.secondary,
        ),
      ],
    );
  }
}

class _Meals extends StatelessWidget {
  const _Meals({required this.entries});

  final List<LoggedEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('Nothing logged yet.', style: AppType.body);
    }

    return Column(
      children: [
        for (final (index, entry) in entries.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RisingCard(index: index, child: MealCard(entry: entry)),
          ),
      ],
    );
  }
}

class _AddButton extends ConsumerWidget {
  const _AddButton({required this.dayKey});

  final int dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showCaptureSheet(context, ref, dayKey: dayKey),
      child: Container(
        width: AppLayout.fabSize,
        height: AppLayout.fabSize,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: AppShadows.primaryGlow,
        ),
        child: const Icon(Icons.add, color: AppColors.surface, size: 26),
      ),
    );
  }
}
