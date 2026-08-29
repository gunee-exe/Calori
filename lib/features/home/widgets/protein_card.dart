/// Protein, with carbs and fat beneath it.
///
/// The hierarchy is deliberate and comes from `01-concept.md`: calories are the
/// headline, protein is the one macro given real weight, and carbs and fat are
/// a footnote. Protein gets a filled bar; the other two get an 8px dot each.
library;

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/calori_card.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/entry.dart';
import '../../../domain/repositories/diary_repository.dart';

class ProteinCard extends StatelessWidget {
  const ProteinCard({super.key, required this.totals, required this.profile});

  final DayTotals totals;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final eaten = totals.consumed.proteinG;
    final target = profile.dailyProteinG;
    final ratio = target <= 0 ? 0.0 : eaten / target;

    return CaloriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: SectionLabel('Protein')),
              Text(
                '${formatGrams(eaten)} / $target g',
                style: AppType.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Pips(ratio: ratio),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              MacroDot(
                color: AppColors.carbs,
                label: 'Carbs',
                value: '${formatGrams(totals.consumed.carbsG)} g',
              ),
              const SizedBox(width: 26),
              MacroDot(
                color: AppColors.fat,
                label: 'Fat',
                value: '${formatGrams(totals.consumed.fatG)} g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Twelve discrete segments rather than a continuous bar.
///
/// Discrete reads as "some of a known number", which is what a daily protein
/// target is. A smooth bar reads as a percentage and invites precision the
/// underlying figure does not have.
class _Pips extends StatelessWidget {
  const _Pips({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    const count = AppLayout.proteinPips;

    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                // Filled once the segment's share of the target is reached.
                color: (i + 1) / count <= ratio
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
