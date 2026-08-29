/// A single search result, which expands in place into a portion picker.
///
/// Serving units are primary and grams secondary, per UC-05: people think in
/// plates and cups, and a gram figure alone makes them guess. The grams stay
/// visible underneath so the estimate is never hidden.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/calori_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/providers.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/food.dart';
import '../../../domain/repositories/diary_repository.dart';

class FoodResultCard extends ConsumerStatefulWidget {
  const FoodResultCard({
    super.key,
    required this.food,
    required this.dayKey,
    this.mealType,
  });

  final Food food;
  final int dayKey;
  final MealType? mealType;

  @override
  ConsumerState<FoodResultCard> createState() => _FoodResultCardState();
}

class _FoodResultCardState extends ConsumerState<FoodResultCard> {
  bool _expanded = false;
  bool _saving = false;

  /// Multiplier applied to the selected portion, or to 100 g when the food has
  /// no household measures.
  double _quantity = 1;

  late FoodPortion? _portion = widget.food.defaultPortion;

  double get _grams =>
      (_portion?.grams ?? 100) * _quantity;

  Macros get _macros => widget.food.macrosFor(_grams);

  String get _portionLabel => _portion == null
      ? '${formatGrams(_grams)} g'
      : '${formatQuantity(_quantity)} × ${_portion!.label}';

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            food: widget.food,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedSize(
            duration: AppMotion.durationFor(context, AppMotion.fadeIn),
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _Picker(
                    food: widget.food,
                    portion: _portion,
                    quantity: _quantity,
                    grams: _grams,
                    macros: _macros,
                    saving: _saving,
                    onPortion: (p) => setState(() => _portion = p),
                    onQuantity: (q) => setState(() => _quantity = q),
                    onSave: _save,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(diaryRepositoryProvider).addEntry(
        dayKey: widget.dayKey,
        mealType: widget.mealType ?? mealTypeForNow(),
        source: ItemSource.db,
        items: [
          NewItem(
            name: widget.food.name,
            grams: _grams,
            macros: _macros,
            source: ItemSource.db,
            portionDesc: _portionLabel,
            // Provenance only. Points into the foods database, which is a
            // separate file and is never joined against.
            foodId: widget.food.id,
          ),
        ],
      );

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${widget.food.name} added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't save that. Try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.food, required this.onTap});

  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final serving = food.defaultPortion;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    food.name,
                    style: AppType.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SourceBadge(food.sourceLabel),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          serving?.label ?? '100 g',
                          style: AppType.secondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${formatKcal(food.macrosFor(serving?.grams ?? 100).kcal)} kcal',
              style: AppType.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.food,
    required this.portion,
    required this.quantity,
    required this.grams,
    required this.macros,
    required this.saving,
    required this.onPortion,
    required this.onQuantity,
    required this.onSave,
  });

  final Food food;
  final FoodPortion? portion;
  final double quantity;
  final double grams;
  final Macros macros;
  final bool saving;
  final ValueChanged<FoodPortion?> onPortion;
  final ValueChanged<double> onQuantity;
  final VoidCallback onSave;

  static const _quantities = [0.5, 1.0, 2.0, 3.0];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Household measures first. Foods with several get all of them; foods
        // with none fall back to grams, which is what the quantity chips then
        // multiply.
        if (food.portions.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in food.portions.take(6))
                SelectableChip(
                  label: p.label,
                  selected: p.label == portion?.label,
                  onTap: () => onPortion(p),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _quantities)
              SelectableChip(
                label: portion == null
                    ? '${formatQuantity(q)} × 100 g'
                    : '${formatQuantity(q)} × ${portion!.label}',
                selected: q == quantity,
                onTap: () => onQuantity(q),
              ),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('${formatGrams(grams)} g', style: AppType.secondary),
            ),
            Text('${formatKcal(macros.kcal)} kcal', style: AppType.sectionHeader),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${formatGrams(macros.proteinG)}P   '
          '${formatGrams(macros.carbsG)}C   '
          '${formatGrams(macros.fatG)}F',
          style: AppType.secondary,
        ),

        const SizedBox(height: 14),
        PillButton(
          label: saving ? 'Saving…' : 'Add to log',
          onPressed: saving ? null : onSave,
        ),
      ],
    );
  }
}
