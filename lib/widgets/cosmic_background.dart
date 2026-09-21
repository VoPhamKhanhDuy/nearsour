import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// auth: nền navy-tím của Welcome/Auth. onboarding: nền #160D35 với glow magenta/cyan của các màn thiết lập.
enum CosmicStyle { auth, onboarding }

/// Nền dark cosmic dùng chung: gradient nhiều lớp, glow mờ, sao và đường chòm sao.
class CosmicBackground extends StatelessWidget {
  final Widget child;
  final CosmicStyle style;

  const CosmicBackground({
    super.key,
    required this.child,
    this.style = CosmicStyle.auth,
  });

  @override
  Widget build(BuildContext context) {
    final onboarding = style == CosmicStyle.onboarding;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: onboarding ? AppColors.onboardingBg : null,
            gradient: onboarding
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.bgTop,
                      AppColors.bgMid,
                      AppColors.bgBottom,
                    ],
                  ),
          ),
        ),
        if (onboarding) ...const [
          _Glow(
            alignment: Alignment.bottomLeft,
            color: AppColors.magenta,
            opacity: 0.40,
            size: 520,
          ),
          _Glow(
            alignment: Alignment.topRight,
            color: AppColors.cyan,
            opacity: 0.35,
            size: 480,
          ),
          _Glow(
            alignment: Alignment.center,
            color: AppColors.deepPurple,
            opacity: 0.50,
            size: 520,
          ),
        ] else ...const [
          _Glow(
            alignment: Alignment(-1.4, -0.5),
            color: AppColors.purple,
            opacity: 0.20,
            size: 300,
          ),
          _Glow(
            alignment: Alignment(1.4, 0.5),
            color: AppColors.cyan,
            opacity: 0.15,
            size: 300,
          ),
          _Glow(
            alignment: Alignment.center,
            color: AppColors.purple,
            opacity: 0.30,
            size: 380,
          ),
        ],
        const RepaintBoundary(
          child: CustomPaint(painter: _StarfieldPainter(), size: Size.infinite),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double opacity;
  final double size;

  const _Glow({
    required this.alignment,
    required this.color,
    required this.opacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Seed cố định để sao không nhảy vị trí mỗi lần repaint.
    final rnd = Random(42);
    final points = <Offset>[];

    final starPaint = Paint();
    for (var i = 0; i < 45; i++) {
      final p = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      points.add(p);
      final isCyan = i % 4 == 0;
      starPaint.color = (isCyan ? AppColors.cyan : Colors.white).withValues(
        alpha: 0.3 + rnd.nextDouble() * 0.2,
      );
      canvas.drawCircle(p, 0.6 + rnd.nextDouble() * 1.2, starPaint);
    }

    // Đường chòm sao: nối vài cặp điểm gần nhau.
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        if ((points[i] - points[j]).distance < size.width * 0.28 &&
            (i + j) % 5 == 0) {
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
