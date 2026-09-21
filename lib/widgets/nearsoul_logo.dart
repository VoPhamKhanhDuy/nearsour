import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo tròn có viền cyan và glow. [size] là đường kính của logo, vùng glow lớn hơn một chút.
class NearSoulLogo extends StatelessWidget {
  final double size;

  const NearSoulLogo({super.key, this.size = 95});

  @override
  Widget build(BuildContext context) {
    final glowSize = size * 105 / 95;
    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cyan.withValues(alpha: 0.35),
                  AppColors.purple.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan, width: 1),
              boxShadow: [
                BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: size * 0.21),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
