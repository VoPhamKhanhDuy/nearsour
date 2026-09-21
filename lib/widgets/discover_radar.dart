import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'avatar_image.dart';

/// Radar của màn Radar Discover.
/// Chờ kích hoạt: tia quét chậm và mờ, tâm nhấp nháy nhẹ. Đang quét: tia quét nhanh và sáng, sóng lan ra từ tâm.
class DiscoverRadar extends StatefulWidget {
  static const double size = 280;

  final bool scanning;
  final int? avatarId;

  const DiscoverRadar({super.key, required this.scanning, required this.avatarId});

  @override
  State<DiscoverRadar> createState() => _DiscoverRadarState();
}

class _DiscoverRadarState extends State<DiscoverRadar> with SingleTickerProviderStateMixin {
  // 60s chia hết cho cả chu kỳ quét (6s / 2.5s) và chu kỳ nhấp nháy (2s) nên vòng lặp không bị giật.
  static const _loop = Duration(seconds: 60);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt "giảm chuyển động": dừng animation, radar vẫn vẽ tĩnh.
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
      label: widget.scanning ? 'Radar đang quét người gần bạn' : 'Radar đang chờ kích hoạt',
      child: SizedBox(
        width: DiscoverRadar.size,
        height: DiscoverRadar.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _DiscoverPainter(_controller, widget.scanning)),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF363051),
                border: Border.all(color: AppColors.lilac, width: 2),
                boxShadow: [BoxShadow(color: AppColors.lilac.withValues(alpha: 0.5), blurRadius: 24)],
              ),
              child: AvatarImage(avatarId: widget.avatarId, size: 54),
            ),
            const Positioned(
              bottom: 100,
              child: Text('Bạn', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverPainter extends CustomPainter {
  final AnimationController t;
  final bool scanning;

  _DiscoverPainter(this.t, this.scanning) : super(repaint: t);

  // (x, y theo tỉ lệ khung, bán kính, cyan?) — vị trí mock của những người xung quanh.
  static const _markers = [
    (0.30, 0.25, 5.0, true),
    (0.80, 0.75, 3.0, false),
    (0.20, 0.65, 4.0, true),
    (0.70, 0.35, 3.0, false),
    (0.45, 0.85, 4.0, true),
    (0.60, 0.15, 3.0, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = t.value * 60;
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    _ring(canvas, c, r, AppColors.cyan, 0.9, 2, glow: 0.35);
    _ring(canvas, c, r * 0.65, AppColors.lilac, 0.6, 1, glow: 0.2);
    _ring(canvas, c, r * 0.35, AppColors.cyan, 0.8, 1, glow: 0.25);

    // Tia quét: vệt mờ dần phía sau cạnh dẫn đầu
    final period = scanning ? 2.5 : 6.0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate((seconds / period) % 1 * 2 * pi);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final sweep = 0.6 * pi; // 108° như thiết kế
    canvas.drawArc(
      rect,
      2 * pi - sweep,
      sweep,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: 2 * pi - sweep,
          endAngle: 2 * pi,
          colors: [
            AppColors.cyan.withValues(alpha: 0),
            AppColors.cyan.withValues(alpha: scanning ? 0.5 : 0.28),
          ],
        ).createShader(rect),
    );
    if (scanning) {
      canvas.drawLine(
        Offset.zero,
        Offset(r, 0),
        Paint()
          ..color = AppColors.cyan.withValues(alpha: 0.8)
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();

    // Sóng nhấp nháy ở tâm (chờ) hoặc lan ra (đang quét)
    final pulse = (seconds / 2) % 1;
    canvas.drawCircle(
      c,
      scanning ? 30 + (r - 30) * pulse : 34 + 12 * pulse,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = (scanning ? AppColors.cyan : AppColors.lilac).withValues(alpha: (scanning ? 0.5 : 0.45) * (1 - pulse)),
    );

    // Các chấm người xung quanh, nhấp nháy lệch pha
    for (var i = 0; i < _markers.length; i++) {
      final (x, y, radius, cyan) = _markers[i];
      final wave = (sin((seconds / 2 + i * 0.17) * 2 * pi) + 1) / 2; // 0..1
      final color = cyan ? AppColors.cyan : AppColors.lilac;
      final p = Offset(size.width * x, size.height * y);
      final scale = 0.8 + 0.4 * wave;
      canvas.drawCircle(
        p,
        radius * 2.2 * scale,
        Paint()
          ..color = color.withValues(alpha: 0.45 * (0.5 + 0.5 * wave))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, radius * scale, Paint()..color = color.withValues(alpha: 0.6 + 0.4 * wave));
    }
  }

  void _ring(Canvas canvas, Offset c, double radius, Color color, double alpha, double width, {required double glow}) {
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 4
        ..color = color.withValues(alpha: glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _DiscoverPainter oldDelegate) => oldDelegate.scanning != scanning;
}
