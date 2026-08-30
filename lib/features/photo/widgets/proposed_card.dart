/// A food the model proposed, awaiting the user's agreement.
///
/// The signature interaction. A low-confidence estimate renders **blurred and
/// dimmed** rather than flagged in a warning colour, and snaps sharp the moment
/// the user commits to a portion.
///
/// The reasoning, from `01-concept.md`: blur is the honest visual metaphor for
/// an uncertain number. A warning colour says "this is wrong"; a blurred number
/// says "this is not settled yet" — which is exactly true, and it makes
/// confirming feel like bringing something into focus rather than correcting a
/// mistake the app made.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/calori_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../data/ai/vision_service.dart';
import '../../../domain/models/enums.dart';

class ProposedCard extends StatefulWidget {
  const ProposedCard({
    super.key,
    required this.item,
    required this.onResize,
    required this.onRemove,
  });

  final ProposedItem item;
  final ValueChanged<double> onResize;
  final VoidCallback onRemove;

  @override
  State<ProposedCard> createState() => _ProposedCardState();
}

class _ProposedCardState extends State<ProposedCard> {
  /// Set once the user picks a portion. Never reset — an item cannot become
  /// unconfirmed, because the number is now theirs rather than the model's.
  bool _confirmed = false;

  bool get _needsConfirming =>
      !_confirmed &&
      !widget.item.fromCache &&
      widget.item.confidence == Confidence.low;

  static const _multipliers = [0.5, 0.75, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final blur = _needsConfirming ? AppConfidence.blurSigma : 0.0;

    return CaloriCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only the numbers blur. The name stays sharp throughout: the user
          // has to be able to read what the app thinks the food *is* in order
          // to judge whether the portion question even makes sense.
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: AppType.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 40,
                  height: 32,
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

          _Blurred(
            sigma: blur,
            // Reduced motion keeps the blur — it carries meaning — but drops
            // the transition into it.
            animate: !reduceMotion,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatKcal(widget.item.macros.kcal)} kcal',
                  style: AppType.sectionHeader,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${formatGrams(widget.item.grams)} g'
                    '${widget.item.portionDesc == null ? '' : ' · ${widget.item.portionDesc}'}',
                    style: AppType.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          _Blurred(
            sigma: blur,
            animate: !reduceMotion,
            child: Text(
              '${formatGrams(widget.item.macros.proteinG)}P   '
              '${formatGrams(widget.item.macros.carbsG)}C   '
              '${formatGrams(widget.item.macros.fatG)}F',
              style: AppType.secondary,
            ),
          ),

          if (_needsConfirming) ...[
            const SizedBox(height: 14),
            Text(
              // The reason, stated plainly. "Low confidence" alone tells the
              // user nothing they can act on; "no reference object in frame"
              // tells them why and implicitly how to help.
              widget.item.confidenceReason,
              style: AppType.secondary.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            const Text('How much was it?', style: AppType.secondary),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final multiplier in _multipliers)
                  SelectableChip(
                    label: multiplier == 1.0
                        ? 'As shown'
                        : '${formatQuantity(multiplier)}×',
                    selected: false,
                    onTap: () => _confirm(widget.item.grams * multiplier),
                  ),
              ],
            ),
          ] else if (widget.item.fromCache) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Using the numbers you accepted before',
                  style: AppType.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirm(double grams) {
    widget.onResize(grams);
    setState(() => _confirmed = true);
  }
}

/// Applies a blur that animates away when it reaches zero.
class _Blurred extends StatelessWidget {
  const _Blurred({
    required this.sigma,
    required this.child,
    this.animate = true,
  });

  final double sigma;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return _blur(sigma, child);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: sigma),
      duration: AppMotion.confidenceSettle,
      curve: AppMotion.standard,
      builder: (context, value, blurred) => _blur(value, blurred!),
      child: Opacity(
        opacity: sigma > 0
            ? AppConfidence.dimOpacity
            : AppConfidence.sharpOpacity,
        child: child,
      ),
    );
  }

  Widget _blur(double value, Widget content) {
    // ImageFiltered with sigma 0 still costs a saveLayer, so it is skipped
    // entirely once the item is confirmed — these cards sit in a list and the
    // photo behind them is already expensive.
    if (value <= 0.01) return content;

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: value, sigmaY: value),
      child: content,
    );
  }
}
