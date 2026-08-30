/// The horizontally scrolling day picker at the top of Home.
///
/// Auto-centres the selected day on first layout and whenever the selection
/// changes, which is what makes the strip feel anchored rather than merely
/// scrollable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/day_key.dart';
import '../providers.dart';

/// Days shown at once. Enough to reach back a week and a half without
/// scrolling, which covers retroactive logging.
const _windowDays = 12;

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DateStrip extends ConsumerStatefulWidget {
  const DateStrip({super.key});

  @override
  ConsumerState<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends ConsumerState<DateStrip> {
  final _scroll = ScrollController();

  static const _chipWidth = 52.0;
  static const _chipGap = 8.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the selected day into view.
  ///
  /// Only needed when the user picks an earlier day; today needs no scroll at
  /// all because the list is reversed (see [_days]).
  void _centre() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;

    final index = _days().indexOf(ref.read(selectedDayProvider));
    if (index < 0) return;

    final viewport = _scroll.position.viewportDimension;
    final target =
        (index * (_chipWidth + _chipGap)) - (viewport - _chipWidth) / 2;

    _scroll.animateTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: AppMotion.durationFor(context, AppMotion.screenIn),
      curve: AppMotion.standard,
    );
  }

  /// The window of days, **newest first**. Future days are not offered — there
  /// is nothing to log against them.
  ///
  /// Reverse chronological, paired with `reverse: true` on the ListView, so the
  /// strip reads left-to-right oldest-to-newest on screen while today sits at
  /// the scroll *origin*. Today is therefore correctly placed on the very first
  /// frame with no scrolling.
  ///
  /// The previous version scrolled to today after layout, and lost the race:
  /// on the first frame the viewport reports no content dimensions, the clamp
  /// pinned the strip to the far left, and today — the one day the user
  /// actually wants — sat half off the right edge.
  List<int> _days() {
    final today = DayKey.today();
    return [
      for (var offset = 0; offset < _windowDays; offset++)
        DayKey.addDays(today, -offset),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDayProvider);
    ref.listen(selectedDayProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centre());
    });

    return SizedBox(
      height: 60,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        // Origin at the right-hand end, where today is.
        reverse: true,
        itemCount: _days().length,
        separatorBuilder: (_, _) => const SizedBox(width: _chipGap),
        itemBuilder: (context, index) {
          final dayKey = _days()[index];
          return _DayChip(
            dayKey: dayKey,
            selected: dayKey == selected,
            onTap: () =>
                ref.read(selectedDayProvider.notifier).select(dayKey),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dayKey,
    required this.selected,
    required this.onTap,
  });

  final int dayKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DayKey.toDate(dayKey);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.durationFor(context, AppMotion.fadeIn),
        curve: AppMotion.standard,
        width: _DateStripState._chipWidth,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppType.mealKcal.copyWith(
                color: selected ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _dayNames[(date.weekday + 6) % 7],
              style: AppType.sourceBadge.copyWith(
                color: selected
                    ? AppColors.surface.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
