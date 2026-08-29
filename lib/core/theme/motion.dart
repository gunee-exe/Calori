/// Motion tokens transcribed from the Bright Blue prototype.
///
/// The prototype's CSS carries a `prefers-reduced-motion` block that collapses
/// every animation to ~0ms. [AppMotion.durationFor] is the Flutter equivalent;
/// route it through that rather than using the raw durations directly, so the
/// accessibility setting is honoured everywhere by construction.
library;

import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  /// The house curve. Fast out of the gate, long gentle settle — used by every
  /// transition except the ring.
  static const standard = Cubic(0.2, 0.9, 0.2, 1.0);

  /// The ring fill curve. Slightly lazier at the start than [standard], which
  /// is what makes a long sweep read as deliberate rather than flung.
  static const ringFill = Cubic(0.22, 0.85, 0.24, 1.0);

  /// Screen entry: fade plus an 8px rise.
  static const screenIn = Duration(milliseconds: 300);
  static const screenInOffset = 8.0;

  /// List item entry: fade plus a 12px rise, staggered by index.
  static const rise = Duration(milliseconds: 380);
  static const riseOffset = 12.0;

  /// Per-index delay for staggered lists. Meal cards use 40ms, the proposed
  /// item cards use 60ms.
  static const riseStaggerShort = Duration(milliseconds: 40);
  static const riseStaggerLong = Duration(milliseconds: 60);

  /// Bottom sheet rising from off-screen.
  static const sheetUp = Duration(milliseconds: 340);

  /// Label crossfades, selection tints.
  static const fadeIn = Duration(milliseconds: 180);

  /// The ring's container scaling in from 0.94 on first paint.
  static const ringIn = Duration(milliseconds: 500);

  /// The ring sweeping from zero to the day's percentage.
  ///
  /// This runs on *every* entry to Home, not just the first — the prototype
  /// re-triggers it on each navigation and day change, and that restatement is
  /// a large part of why the screen feels alive.
  static const ringSweep = Duration(milliseconds: 950);

  /// Skeleton shimmer sweep. Linear, infinite.
  static const shimmer = Duration(milliseconds: 1400);

  /// The Save button's 4px hop on commit.
  static const savePop = Duration(milliseconds: 420);

  /// Blur/opacity settle when a low-confidence item is confirmed.
  static const confidenceSettle = Duration(milliseconds: 260);

  /// Collapses [d] to a single frame when the platform requests reduced motion.
  ///
  /// Returning [Duration.zero] would skip `AnimationController` callbacks in
  /// some paths, so this returns 1ms — matching the prototype's `.001ms`.
  static Duration durationFor(BuildContext context, Duration d) {
    return MediaQuery.disableAnimationsOf(context)
        ? const Duration(milliseconds: 1)
        : d;
  }

  /// Stagger delay for the item at [index], capped so a long list does not
  /// leave the last rows visibly late.
  static Duration staggerFor(
    int index, {
    Duration step = riseStaggerShort,
    int maxSteps = 8,
  }) {
    final steps = index < maxSteps ? index : maxSteps;
    return step * steps;
  }
}

/// Low-confidence presentation for an AI-proposed item.
///
/// The signature interaction of the app: uncertainty is rendered as *softness*,
/// never as a warning colour. An unconfirmed item sits blurred and dimmed with
/// "tap to confirm portion" beneath it; confirming snaps it sharp.
abstract final class AppConfidence {
  static const blurSigma = 3.0;
  static const dimOpacity = 0.55;
  static const sharpOpacity = 1.0;
}
