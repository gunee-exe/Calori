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
    this.editable = false,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Draws a pencil beside **Protein**, for the one place this row can be
  /// tapped to change something.
  ///
  /// Off by default, so the search results and the photo proposals — where
  /// these figures are output, not input — are unaffected. Carbs and fat never
  /// get one: they are derived from the calorie target and the protein figure,
  /// so a pencil on them would promise an edit that does not exist.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    // Expanded thirds rather than spaceBetween. Three equal columns look the
    // same either way at a comfortable width, but spaceBetween sizes each to
    // its content and overflows a 320pt phone as soon as one of them grows —
    // which is exactly what the Protein pencil did.
    return Row(
      children: [
        Expanded(
          child: _Macro(
            label: 'Protein',
            grams: proteinG,
            colour: AppColors.primary,
            editable: editable,
          ),
        ),
        Expanded(
          child: _Macro(label: 'Carbs', grams: carbsG, colour: AppColors.carbs),
        ),
        Expanded(
          child: _Macro(label: 'Fat', grams: fatG, colour: AppColors.fat),
        ),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.grams,
    required this.colour,
    this.editable = false,
  });

  final String label;
  final double grams;
  final Color colour;
  final bool editable;

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
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppType.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (editable) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_outlined,
                size: 12,
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
