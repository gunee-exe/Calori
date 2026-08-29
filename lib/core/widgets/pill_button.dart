/// Stadium-shaped buttons and chips.
///
/// Every interactive surface in the prototype is a pill and is at least 44px
/// tall. Material's ink ripple is deliberately absent throughout — presses are
/// expressed as a background-colour change, which is what the design does.
library;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

enum PillVariant {
  /// Blue fill, white label, tinted shadow. The commit action on a screen —
  /// Save, Done. At most one per screen.
  primary,

  /// Pale blue fill, blue label. A secondary commit, like "Confirm portion".
  tonal,

  /// White fill, hairline border. Used over a photo and in sheets.
  surface,

  /// No fill at all. "+ Add item".
  ghost,
}

class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.expand = true,
    this.minHeight = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;

  /// Whether to fill the available width.
  final bool expand;

  final double minHeight;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (bg, fg) = _colors(enabled);

    final content = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedContainer(
        duration: AppMotion.durationFor(context, AppMotion.fadeIn),
        curve: AppMotion.standard,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          border: widget.variant == PillVariant.surface
              ? Border.all(color: AppColors.border)
              : null,
          boxShadow: widget.variant == PillVariant.primary && enabled
              ? AppShadows.primaryGlow
              : null,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          widget.label,
          style: AppType.body.copyWith(color: fg),
          textAlign: TextAlign.center,
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      behavior: HitTestBehavior.opaque,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }

  (Color, Color) _colors(bool enabled) {
    if (!enabled) return (AppColors.border, AppColors.textTertiary);

    return switch (widget.variant) {
      PillVariant.primary => (
        _down ? AppColors.primaryPressed : AppColors.primary,
        AppColors.surface,
      ),
      PillVariant.tonal => (
        _down ? AppColors.primaryContainerPressed : AppColors.primaryContainer,
        AppColors.primary,
      ),
      PillVariant.surface => (
        _down ? AppColors.primaryContainer : AppColors.surface,
        AppColors.textPrimary,
      ),
      PillVariant.ghost => (Colors.transparent, AppColors.primary),
    };
  }
}

/// A selectable chip: portion options, recent foods, unit multipliers.
///
/// Selection is carried by border and fill together rather than fill alone, so
/// it survives being viewed in greyscale or by someone who cannot separate the
/// blue from the white.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.fadeIn),
          curve: AppMotion.standard,
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppType.secondary.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
