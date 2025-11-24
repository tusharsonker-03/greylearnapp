import 'package:flutter/material.dart';

import '../constants.dart';
import '../widgets/custom_text.dart';

/// A simple bar that draws at [percent] (0–100).
class SimpleProgressBar extends StatelessWidget {
  final double percent;
  const SimpleProgressBar({ Key? key, required this.percent }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth * (percent / 100);
      return Container(
        width: constraints.maxWidth,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(3),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width,
            height: 6,
            decoration: BoxDecoration(
              color: kGreenColorColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    });
  }
}

/// Animated version that tweens from 0 → [targetPercent].
class AnimatedSimpleProgressBar extends StatelessWidget {
  /// final progress percentage (0–100)
  final double targetPercent;

  /// how long the animation takes
  final Duration duration;

  const AnimatedSimpleProgressBar({
    Key? key,
    required this.targetPercent,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: targetPercent),
      duration: duration,
      builder: (context, animatedValue, child) {
        // animatedValue will go from 0.0 → targetPercent
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: '${animatedValue.toInt()}%',
              colors: kTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(height: 6),
            // reuse your SimpleProgressBar but feed it the animated value
            SimpleProgressBar(percent: animatedValue),
          ],
        );
      },
    );
  }
}
