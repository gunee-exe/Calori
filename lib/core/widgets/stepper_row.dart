/// A labelled value with a minus and a plus.
///
/// The Goal screen's editing control. Steppers rather than text fields because
/// changing a goal is nearly always a nudge — a kilo either way, half a percent
/// slower — and a keyboard for that is three taps too many. It also means the
/// value can never be nonsense: there is no state in which the field holds
/// "7800" and the engine has to decide what to do about it.
library;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.step = 1,
    this.min = 0,
    this.max = 999,
    this.decimals = 0,
    this.suffix = '',
  });

  final String label;

  /// Secondary line under the label: "kilograms", "% of bodyweight per week".
  final String? detail;

  final double value;
  final ValueChanged<double> onChanged;

  final double step;
  final double min;
  final double max;

  /// Decimal places to show. Rate of loss needs one; weights need none.
  final int decimals;

  final String suffix;

  bool get _canDecrease => value - step >= min - 0.0001;
  bool get _canIncrease => value + step <= max + 0.0001;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.body),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!, style: AppType.caption),
                ],
              ],
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            // Rounded away from floating-point drift: repeatedly adding 0.1
            // otherwise lands on 0.7000000000000001, which then renders as
            // "0.7" but compares unequal to it.
            onTap: _canDecrease
                ? () => onChanged(_rounded(value - step))
                : null,
            semanticLabel: 'Decrease $label',
          ),
          SizedBox(
            width: 74,
            child: Text(
              '${value.toStringAsFixed(decimals)}$suffix',
              style: AppType.bodyStrong,
              textAlign: TextAlign.center,
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: _canIncrease
                ? () => onChanged(_rounded(value + step))
                : null,
            semanticLabel: 'Increase $label',
          ),
        ],
      ),
    );
  }

  double _rounded(double raw) {
    final factor = decimals == 0 ? 1 : (decimals == 1 ? 10 : 100);
    return (raw * factor).round() / factor;
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // The visible circle is 36, but the tap target is the full 44 the
          // rest of the app commits to.
          width: AppLayout.minTapTarget,
          height: AppLayout.minTapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.durationFor(context, AppMotion.fadeIn),
              curve: AppMotion.standard,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: enabled ? AppColors.border : AppColors.bg,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textTertiary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
