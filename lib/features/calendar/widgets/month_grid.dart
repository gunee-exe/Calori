/// The month grid.
///
/// Each cell is a small ring, not a coloured square. A ring says "this much of
/// your day" — a square would have to encode the same thing as a colour, and
/// the only colours available for that read as pass and fail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../domain/models/day_key.dart';
import '../../../domain/models/entry.dart';
import '../providers.dart';

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class MonthGrid extends ConsumerWidget {
  const MonthGrid({super.key, required this.totals});

  final Map<int, DayTotals> totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCalendarDayProvider);
    final today = DayKey.today();

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdays)
              Expanded(
                child: Center(
                  child: Text(label, style: AppType.sectionLabel),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Grid(totals: totals, selected: selected, today: today),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        const CalendarLegend(),
      ],
    );
  }
}

/// What the rings mean.
///
/// Three states need distinguishing and only two of them are a ring, so a key
/// is not decoration here — without it, the grey ring and the small dot are
/// indistinguishable guesses.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row: three keys plus their labels overflow a narrow phone by
    // about 16px, and a legend that clips is worse than one on two lines.
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        _Key(colour: AppColors.primary, label: 'on target'),
        _Key(colour: AppColors.neutralOver, label: 'over'),
        _Key(colour: AppColors.neutralOver, label: 'not logged', dot: true),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.colour, required this.label, this.dot = false});

  final Color colour;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A ring for the two logged states, a dot for the absent one — the
        // same shapes the grid uses, at the same weight.
        Container(
          width: dot ? 5 : 11,
          height: dot ? 5 : 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot ? colour : null,
            border: dot ? null : Border.all(color: colour, width: 1.6),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppType.caption),
      ],
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({
    required this.totals,
    required this.selected,
    required this.today,
  });

  final Map<int, DayTotals> totals;
  final int? selected;
  final int today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final cells = monthGridCells(month.year, month.month);

    return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final dayKey = cells[index];
            if (dayKey == null) return const SizedBox.shrink();

            return _DayCell(
              dayKey: dayKey,
              totals: totals[dayKey],
              isToday: dayKey == today,
              isSelected: dayKey == selected,
              isFuture: dayKey > today,
              onTap: () => ref
                  .read(selectedCalendarDayProvider.notifier)
                  .select(dayKey == selected ? null : dayKey),
            );
          },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayKey,
    required this.totals,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.onTap,
  });

  final int dayKey;
  final DayTotals? totals;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = DayKey.toDate(dayKey).day;
    final logged = totals?.isLogged ?? false;

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: _semanticLabel(day),
      child: GestureDetector(
        onTap: isFuture ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.fadeIn),
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Center(
            child: logged
                ? MiniRing(
                    progress: totals!.progress,
                    size: 34,
                    stroke: 3,
                    center: Text('$day', style: AppType.calendarDay),
                  )
                : Opacity(
                    // A future day is dimmer still: nothing happened there yet,
                    // and nothing can.
                    opacity: isFuture ? 0.32 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$day', style: AppType.calendarDay),
                        const SizedBox(height: 3),
                        // An unlogged day is absent, not a failure. It gets a
                        // small neutral dot rather than an empty ring, which
                        // would read as zero progress.
                        if (!isFuture)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.neutralOver,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(int day) {
    if (isFuture) return '$day, not yet';
    if (totals == null || !totals!.isLogged) return '$day, nothing logged';
    final percent = (totals!.progress * 100).round();
    return '$day, $percent percent of target'
        '${totals!.isOver ? ', over' : ''}';
  }
}
