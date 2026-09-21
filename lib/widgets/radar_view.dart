import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Radar minh họa "người gần bạn": 3 vòng 50m/100m/200m, tia quét xoay và các chấm nhấp nháy.
/// Kích thước logic cố định [size]; bọc trong FittedBox nếu cần co lại.
class RadarView extends StatefulWidget {
  static const double size = 300;

  const RadarView({super.key});

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt "giảm chuyển động" của hệ thống: dừng animation, radar vẫn vẽ tĩnh.
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
      label: 'Radar tìm người trong bán kính 200 mét',
      child: ExcludeSemantics(
        child: SizedBox(
          width: RadarView.size,
          height: RadarView.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _RadarPainter(_controller)),
                ),
              ),
              const Positioned(top: 6, right: -34, child: _RadarBadge(label: '12 người gần bạn')),
              const Positioned(bottom: 16, left: -20, child: _RadarBadge(label: 'bán kính 200m')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarBadge extends StatelessWidget {
  final String label;

  const _RadarBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.8), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Animation<double> t;

  _RadarPainter(this.t) : super(repaint: t);

  // (góc rad, tỉ lệ khoảng cách so với bán kính) — vị trí mock của những người quanh đây.
  static const _blips = [(-2.4, 0.72), (-0.2, 0.86), (0.8, 0.52), (2.55, 0.64), (-1.2, 0.4)];
  static const _labels = ['50m', '100m', '200m'];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Nền đĩa radar
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.cyan.withValues(alpha: 0.12), AppColors.cyan.withValues(alpha: 0.02)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Đường ngắm ngang/dọc
    final gridPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), gridPaint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), gridPaint);

    // 3 vòng: càng gần tâm càng đậm
    for (var i = 0; i < 3; i++) {
      final ringR = r * (i + 1) / 3;
      canvas.drawCircle(
        c,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - i * 0.5
          ..color = AppColors.cyan.withValues(alpha: 0.55 - i * 0.18),
      );
      final label = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: TextStyle(color: AppColors.cyan.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(c.dx - label.width / 2, c.dy - ringR + 4));
    }

    // Tia quét: vệt mờ dần phía sau cạnh dẫn đầu, cạnh dẫn đầu là một đường sáng.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t.value * 2 * pi);
    final sweepRect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawArc(
      sweepRect,
      1.5 * pi,
      pi / 2,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: 1.5 * pi,
          endAngle: 2 * pi,
          colors: [AppColors.cyan.withValues(alpha: 0), AppColors.cyan.withValues(alpha: 0.35)],
        ).createShader(sweepRect),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    // Những người xung quanh: chấm magenta có sóng lan ra
    for (var i = 0; i < _blips.length; i++) {
      final (angle, frac) = _blips[i];
      final p = c + Offset(cos(angle), sin(angle)) * (r * frac);
      final pulse = (t.value * 2 + i * 0.23) % 1;
      canvas.drawCircle(
        p,
        6 + 16 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.magenta.withValues(alpha: 0.55 * (1 - pulse)),
      );
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = AppColors.magenta.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, 5.5, Paint()..color = AppColors.magenta);
    }

    // Bạn ở tâm
    canvas.drawCircle(
      c,
      16,
      Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      c,
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.cyan.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c, 7, Paint()..color = AppColors.cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
