/// The white card every screen is built from, and its tappable variant.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

/// A white surface with the prototype's two-shadow elevation.
///
/// The elevation is a composited pair rather than Material's single shadow: at
/// this palette's low contrast one soft shadow reads flat, so a tight near
/// shadow supplies the edge and a wide far shadow supplies the lift.
class CaloriCard extends StatelessWidget {
  const CaloriCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    this.radius = AppRadius.md,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// When set, the card lifts slightly on press.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: shape,
        boxShadow: AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return surface;

    return _PressableCard(radius: radius, onTap: onTap!, child: surface);
  }
}

class _PressableCard extends StatefulWidget {
  const _PressableCard({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  final Widget child;
  final VoidCallback onTap;
  final double radius;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        // A press reads as the card moving under the finger. Scale rather than
        // a ripple: the prototype has no Material ink anywhere.
        scale: _down ? 0.985 : 1.0,
        duration: AppMotion.durationFor(context, AppMotion.fadeIn),
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// A card that fades and rises into place, staggered by its position in a list.
///
/// Wraps the prototype's `rise` animation. [index] drives the delay, so the
/// first row lands immediately and each subsequent one follows.
class RisingCard extends StatefulWidget {
  const RisingCard({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = AppMotion.riseStaggerShort,
  });

  final Widget child;
  final int index;
  final Duration stagger;

  @override
  State<RisingCard> createState() => _RisingCardState();
}

class _RisingCardState extends State<RisingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.rise,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final delay = AppMotion.staggerFor(widget.index, step: widget.stagger);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
      if (!mounted) return;
    }
    // Unawaited by design: the controller is disposed below, and awaiting the
    // forward() would keep this frame's async gap open for no benefit.
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.standard,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, AppMotion.riseOffset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
