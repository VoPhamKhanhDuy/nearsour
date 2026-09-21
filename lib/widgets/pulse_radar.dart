import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Minh họa "định vị": ghim ở tâm, 3 vòng tĩnh, sóng lan ra liên tục và vài chấm người trôi nhẹ.
class PulseRadar extends StatefulWidget {
  static const double size = 260;

  const PulseRadar({super.key});

  @override
  State<PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<PulseRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt "giảm chuyển động": dừng animation, vẫn vẽ tĩnh.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Radar định vị',
      child: ExcludeSemantics(
        child: SizedBox(
          width: PulseRadar.size,
          height: PulseRadar.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _PulsePainter(_controller)),
                ),
              ),
              Icon(
                Icons.location_on,
                size: 52,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: AppColors.magenta.withValues(alpha: 0.9),
                    blurRadius: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final Animation<double> t;

  _PulsePainter(this.t) : super(repaint: t);

  // (góc rad, tỉ lệ khoảng cách, cyan?) — vài người xung quanh.
  static const _dots = [
    (-2.3, 0.72, false),
    (-0.6, 0.62, true),
    (0.5, 0.9, false),
    (2.4, 0.7, true),
    (3.5, 0.5, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // 3 vòng tĩnh, càng ra ngoài càng mờ
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        c,
        r * (i + 1) / 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 + (i == 2 ? 0.5 : 0)
          ..color = AppColors.magenta.withValues(alpha: 0.22 + i * 0.05),
      );
    }

    // 3 sóng lan ra lệch pha
    for (var i = 0; i < 3; i++) {
      final phase = (t.value + i / 3) % 1;
      canvas.drawCircle(
        c,
        12 + (r - 12) * phase,
        Paint()
          ..color = AppColors.magenta.withValues(alpha: 0.35 * (1 - phase)),
      );
    }

    // Chấm người trôi nhẹ lên xuống
    for (var i = 0; i < _dots.length; i++) {
      final (angle, frac, cyan) = _dots[i];
      final float = sin(t.value * 2 * pi + i * 1.3) * 5;
      final p =
          c + Offset(cos(angle), sin(angle)) * (r * frac) + Offset(0, float);
      final color = cyan ? AppColors.cyan : AppColors.magenta;
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(p, cyan ? 3 : 4.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
