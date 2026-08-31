/// One logged meal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/calori_card.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/providers.dart';
import '../../../domain/models/entry.dart';
import 'entry_sheet.dart';
import '../../../domain/repositories/diary_repository.dart';

class MealCard extends ConsumerWidget {
  const MealCard({super.key, required this.entry});

  final LoggedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) => _delete(context, ref),
      child: CaloriCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showEntrySheet(context, entry.id),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(
                    entry.mealType.label,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.summary,
                    style: AppType.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatKcal(entry.totals.kcal), style: AppType.mealKcal),
                const Text('kcal', style: AppType.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(diaryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    await repository.deleteEntry(entry.id);

    messenger.showSnackBar(
      SnackBar(
        content: Text('${entry.summary} removed'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          // Re-inserts rather than restores: the row is gone, so this creates
          // an equivalent entry. Ids change, which nothing depends on.
          onPressed: () => repository.addEntry(
            dayKey: entry.dayKey,
            mealType: entry.mealType,
            source: entry.source,
            photoPath: entry.photoPath,
            note: entry.note,
            items: [
              for (final item in entry.items)
                NewItem(
                  name: item.name,
                  grams: item.grams,
                  macros: item.macros,
                  source: item.source,
                  portionDesc: item.portionDesc,
                  confidence: item.confidence,
                  confidenceReason: item.confidenceReason,
                  foodId: item.foodId,
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    // Grey, not red. Removing a meal is a correction, not a punishment, and
    // there is no red anywhere in this app.
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.neutralOver,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.delete_outline, color: AppColors.surface),
    );
  }
}
