/// Editing a logged meal (UC-09).
///
/// *"Tap an entry to edit items, portions, or meal type."* Until this existed
/// the sheet was read-only, so the only way to fix one wrong portion was
/// deleting the whole meal and logging it again.
///
/// Everything here writes straight through the repository. Nothing is staged
/// and there is no Save button: Drift re-emits the day on every write, so the
/// ring and the totals behind the sheet move as you press. A correction should
/// not need confirming.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/providers.dart';
import '../../../domain/models/entry.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/repositories/diary_repository.dart';
import '../providers.dart';

Future<void> showEntrySheet(BuildContext context, int entryId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (_) => EntrySheet(entryId: entryId),
  );
}

class EntrySheet extends ConsumerWidget {
  const EntrySheet({super.key, required this.entryId});

  final int entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not passed in: deleting the last item removes the entry, and
    // the sheet has to notice that rather than render a ghost.
    final entries = ref.watch(entriesForSelectedDayProvider).value ?? const [];
    final entry = entries.where((e) => e.id == entryId).firstOrNull;

    if (entry == null) {
      // The entry went away under us — its last item was removed. Close on the
      // next frame rather than showing an empty sheet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Grabber(),
            const SizedBox(height: 16),

            if (entry.photoPath != null) ...[
              _EntryPhoto(path: entry.photoPath!),
              const SizedBox(height: 18),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Expanded(child: SectionLabel('Meal')),
                Text(
                  '${formatKcal(entry.totals.kcal)} kcal',
                  style: AppType.bodyStrong,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MealPicker(entry: entry),

            const SizedBox(height: 22),
            const SectionLabel('Items'),
            const SizedBox(height: 10),
            for (final item in entry.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EditableItem(item: item),
              ),

            const SizedBox(height: 8),
            PillButton(
              label: 'Remove this meal',
              variant: PillVariant.surface,
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref.read(diaryRepositoryProvider).deleteEntry(entry.id);
                navigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The photo this entry came from, when it came from one.
///
/// Shown so a past estimate can be checked against what was actually eaten,
/// which is the premise of the whole photo path.
class _EntryPhoto extends StatelessWidget {
  const _EntryPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    // Android clears app storage without asking. A missing photo must not
    // break a meal that is otherwise fine, so this fails to nothing.
    if (!file.existsSync()) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _MealPicker extends ConsumerWidget {
  const _MealPicker({required this.entry});

  final LoggedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final meal in MealType.values)
          SelectableChip(
            label: meal.label,
            selected: meal == entry.mealType,
            onTap: () => ref
                .read(diaryRepositoryProvider)
                .updateEntryMeal(entry.id, meal),
          ),
      ],
    );
  }
}

/// One item, with its portion adjustable in place.
class _EditableItem extends ConsumerWidget {
  const _EditableItem({required this.item});

  final LoggedItem item;

  /// Multipliers applied to the portion as it currently stands.
  ///
  /// 1.0 is deliberately absent: it would be a no-op, and a chip labelled "as
  /// logged" would read as "reset", which it is not — after one adjustment the
  /// stored amount *is* what was logged.
  static const _multipliers = [0.5, 0.75, 1.5, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diary = ref.read(diaryRepositoryProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppType.body),
                    const SizedBox(height: 2),
                    Text(
                      '${formatGrams(item.grams)} g · '
                      '${formatKcal(item.macros.kcal)} kcal',
                      style: AppType.secondary,
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Remove ${item.name}',
                child: GestureDetector(
                  onTap: () => diary.deleteItem(item.id),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: AppLayout.minTapTarget,
                    height: AppLayout.minTapTarget,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final multiplier in _multipliers)
                SelectableChip(
                  label: '${formatQuantity(multiplier)}×',
                  selected: false,
                  onTap: () => _rescale(diary, multiplier),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rescales relative to what is currently stored.
  ///
  /// The item is re-read from the day's stream on every rebuild, so 2× then
  /// 0.5× lands back where it started rather than compounding.
  void _rescale(DiaryRepository diary, double multiplier) {
    diary.updateItem(
      item.id,
      grams: item.grams * multiplier,
      macros: item.macros.scaled(multiplier),
    );
  }
}
