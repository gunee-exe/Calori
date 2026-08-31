/// Protein, carbs and fat, each named in full.
///
/// These were rendered as `24P   61C   9F` in the search results and the photo
/// proposals. That is not merely terse, it is ambiguous: `C` reads as calories
/// at least as readily as carbs, and in review it was in fact read that way.
/// Only `F` is unambiguous, and one letter in three is not a legend.
///
/// One widget, so search, photo review and the goal card describe macros
/// identically. Lifted out of the Goal screen, which already did it properly.
library;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

class MacroRow extends StatelessWidget {
  const MacroRow({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Macro(label: 'Protein', grams: proteinG, colour: AppColors.primary),
        _Macro(label: 'Carbs', grams: carbsG, colour: AppColors.carbs),
        _Macro(label: 'Fat', grams: fatG, colour: AppColors.fat),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.grams,
    required this.colour,
  });

  final String label;
  final double grams;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text('${formatGrams(grams)} g', style: AppType.bodyStrong),
        const SizedBox(height: 2),
        Text(label, style: AppType.caption),
      ],
    );
  }
}
