/// The calorie ring from the Bright Blue prototype.
///
/// The app's signature element, and the place its central promise is kept or
/// broken. Going over target does **not** turn the ring red: the main arc fills
/// and a second, dimmer lap is drawn inside it in [AppColors.neutralOver]. Over
/// budget is information, not a verdict.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    this.size = AppLayout.ringSize,
    this.stroke = AppLayout.ringStroke,
    this.animate = true,
    this.center,
  });

  /// Consumed over target. May exceed 1: values above 1 draw the second lap.
  final double progress;

  final double size;
  final double stroke;

  /// Whether to sweep from zero on build.
  ///
  /// The prototype re-triggers this on every entry to Home and on every day
  /// change, not just the first paint. That restatement is a large part of why
  /// the screen feels alive, so it is the default.
  final bool animate;

  final Widget? center;

  /// The most of the available width the ring may occupy.
  static const _maxWidthFraction = 0.62;

  @override
  Widget build(BuildContext context) {
    final target = progress.isFinite && progress > 0 ? progress : 0.0;
    final duration = AppMotion.durationFor(context, AppMotion.ringSweep);

    // The design's 224 assumes a ~390pt viewport. On a narrower one — a small
    // phone, a high display-density setting, or a large system font — a fixed
    // 224 swells to most of the width and pushes the protein card under the
    // add button. Capping it as a fraction of what the parent actually offers
    // keeps the proportion the design intends at every size.
    //
    // Measured from the parent's constraints rather than MediaQuery: the ring
    // should answer to the box it is given, and a MediaQuery that reports no
    // size — which happens whenever one is substituted wholesale — must not be
    // able to produce a negative radius.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final resolved = available.isFinite && available > 0
            ? math.min(size, available * _maxWidthFraction)
            : size;
        final scaled = stroke * (resolved / size);

        return SizedBox(
          width: resolved,
          height: resolved,
          child: TweenAnimationBuilder<double>(
            // Keyed on the target so a day change re-runs the sweep rather
            // than interpolating from wherever the previous day landed.
            key: ValueKey(animate ? target : null),
            tween: Tween(begin: animate ? 0.0 : target, end: target),
            duration: animate ? duration : Duration.zero,
            curve: AppMotion.ringFill,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _RingPainter(progress: value, stroke: scaled),
                child: child,
              );
            },
            child: center == null ? null : Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  /// Twelve o'clock. Flutter's arcs start at three, so everything is offset.
  static const _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = AppColors.ringTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final swept = progress.clamp(0.0, 1.0);
    if (swept > 0) {
      final arc = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryPressed],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, _startAngle, 2 * math.pi * swept, false, arc);
    }

    // The over-target lap. A second, quieter ring inside the first — never a
    // colour change on the main arc.
    if (progress > 1) {
      final overRadius = radius * AppLayout.ringOverRadiusFactor;
      final overRect = Rect.fromCircle(center: centre, radius: overRadius);
      final over = (progress - 1).clamp(0.0, 1.0);

      canvas.drawArc(
        overRect,
        _startAngle,
        2 * math.pi * over,
        false,
        Paint()
          ..color = AppColors.neutralOver
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppLayout.ringOverStroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.stroke != stroke;
}

/// The small ring drawn in a calendar cell and on the day summary card.
///
/// Same grammar as [CalorieRing] at a smaller scale: an arc for what was eaten,
/// [AppColors.neutralOver] rather than red when the day ran over.
class MiniRing extends StatelessWidget {
  const MiniRing({
    super.key,
    required this.progress,
    this.size = 40,
    this.stroke = 3,
    this.center,
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniRingPainter(progress: progress, stroke: stroke),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({required this.progress, required this.stroke});

  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = AppColors.miniRingTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    final swept = progress.clamp(0.0, 1.0);
    if (swept <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * swept,
      false,
      Paint()
        ..color = progress > 1 ? AppColors.neutralOver : AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.stroke != stroke;
}
