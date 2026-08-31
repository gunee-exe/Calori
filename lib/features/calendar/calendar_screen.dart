/// The month view (UC-08).
///
/// A record, not a report card. Streaks are deliberately absent: a streak turns
/// a missed day into a loss of something earned, which is the single most
/// reliable way to make someone stop opening an app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/section_label.dart';
import '../../domain/models/day_key.dart';
import '../../domain/models/entry.dart';
import 'providers.dart';
import 'widgets/month_grid.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthTotalsProvider).value ?? const {};
    final selected = ref.watch(selectedCalendarDayProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          // Clears the floating nav bar, which draws over this content.
          padding: AppLayout.screenPadding.add(
            const EdgeInsets.only(bottom: AppLayout.navClearance),
          ),
          children: [
            const _MonthHeader(),
            const SizedBox(height: 18),
            CaloriCard(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              radius: AppRadius.lg,
              child: MonthGrid(totals: totals),
            ),
            const SizedBox(height: 18),
            if (selected == null)
              const _MonthSummary()
            else
              _DayDetail(dayKey: selected, totals: totals[selected]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final notifier = ref.read(visibleMonthProvider.notifier);
    final label = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(month.year, month.month));

    return Row(
      children: [
        _Arrow(icon: Icons.chevron_left, onTap: notifier.previous),
        Expanded(
          child: Center(child: Text(label, style: AppType.screenTitle)),
        ),
        _Arrow(
          icon: Icons.chevron_right,
          // Disabled rather than hidden: a control that vanishes makes the
          // header jump, and its absence should read as "nothing there yet".
          onTap: notifier.canGoForward ? notifier.next : null,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.minTapTarget,
      height: AppLayout.minTapTarget,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: AppColors.textPrimary,
        disabledColor: AppColors.textTertiary.withValues(alpha: 0.4),
      ),
    );
  }
}

class _MonthSummary extends ConsumerWidget {
  const _MonthSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider);

    if (summary.loggedDays == 0) {
      return const CaloriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('This month'),
            SizedBox(height: 8),
            Text('Nothing logged yet this month.', style: AppType.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two figures, not four. The design shows an average and a count, and
        // that is the honest summary of a month: what a typical day looked
        // like, and how much of the month there is evidence for.
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Average',
                value: formatKcal(summary.avgKcal.toDouble()),
                detail: 'kcal per logged day',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Logged',
                value: '${summary.loggedDays}',
                detail: 'days this month',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;

  /// The qualifier that keeps the number honest — "per *logged* day" rather
  /// than per day, because dividing by the whole month would drag every
  /// average toward zero for anyone who missed one.
  final String detail;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 6),
          Text(value, style: AppType.statNumber),
          const SizedBox(height: 2),
          Text(detail, style: AppType.caption),
        ],
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.dayKey, required this.totals});

  final int dayKey;
  final DayTotals? totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(selectedCalendarDayEntriesProvider).value ?? [];
    final consumed = totals?.consumed.kcal ?? 0;
    final hasTarget = totals != null && totals!.targetKcal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(formatDayKeyShort(dayKey))),
            GestureDetector(
              onTap: () =>
                  ref.read(selectedCalendarDayProvider.notifier).select(null),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: AppLayout.minTapTarget,
                height: 28,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CaloriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatKcal(consumed), style: AppType.dayKcal),
                  const SizedBox(width: 6),
                  Text(
                    hasTarget
                        ? 'of ${formatKcal(totals!.targetKcal.toDouble())} kcal'
                        : 'kcal',
                    style: AppType.secondary,
                  ),
                ],
              ),
              if (totals != null && totals!.isLogged) ...[
                const SizedBox(height: 4),
                Text(
                  totals!.isOver ? 'over target' : 'within target',
                  style: AppType.secondary,
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    MacroDot(
                      color: AppColors.primary,
                      label: 'Protein',
                      value: '${formatGrams(totals!.consumed.proteinG)} g',
                    ),
                    const SizedBox(width: 18),
                    MacroDot(
                      color: AppColors.carbs,
                      label: 'Carbs',
                      value: '${formatGrams(totals!.consumed.carbsG)} g',
                    ),
                  ],
                ),
              ],
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.summary,
                            style: AppType.secondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatKcal(entry.totals.kcal),
                          style: AppType.secondary,
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  DayKey.today() == dayKey
                      ? 'Nothing logged yet today.'
                      : 'Nothing was logged on this day.',
                  style: AppType.secondary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
