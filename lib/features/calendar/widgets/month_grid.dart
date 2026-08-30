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
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedCalendarDayProvider);
    final cells = monthGridCells(month.year, month.month);
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
        GridView.builder(
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
        ),
      ],
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
