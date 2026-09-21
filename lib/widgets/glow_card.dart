import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card dùng chung: nền sáng hơn nền chính, viền magenta mờ, glow nhẹ để "nổi" khỏi nền.
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.magenta.withValues(alpha: 0.18), blurRadius: 24),
        ],
      ),
      child: child,
    );
  }
}
