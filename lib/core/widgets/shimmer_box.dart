/// Loading skeletons.
///
/// Used in two places: the centre of the calorie ring on a cold start, and the
/// three placeholder rows shown while a photo is being analysed.
///
/// A skeleton rather than a spinner is a deliberate choice. A spinner says
/// "waiting"; a skeleton says "this shape is coming", which matters on the
/// review screen where the user is about to be asked to check numbers.
library;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 96,
    this.radius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = SizedBox(width: widget.width, height: widget.height);
    final shape = BorderRadius.circular(widget.radius);

    // A moving highlight is decoration, not information. With reduced motion
    // on, the flat base colour still communicates "content pending".
    if (MediaQuery.disableAnimationsOf(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: shape,
        ),
        child: box,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweeps from fully off the left edge to fully off the right.
        final t = _controller.value * 3 - 1.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment(t - 0.6, -0.3),
              end: Alignment(t + 0.6, 0.3),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
          child: child,
        );
      },
      child: box,
    );
  }
}
