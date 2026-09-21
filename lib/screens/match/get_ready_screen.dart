import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/status_badge.dart';
import '../quiz/quiz_placeholder_screen.dart';

/// Get Ready: cả hai đã đồng ý kết nối, đếm ngược 3 → 2 → 1 → "Bắt đầu!" rồi tự vào AI Quiz.
/// Không thoát được giữa chừng để hai bên vào Quiz cùng lúc.
class GetReadyScreen extends StatefulWidget {
  final AppUser me;
  final AppUser partner;

  /// Thời gian giữa hai nhịp đếm và thời gian giữ chữ "Bắt đầu!" (chỉnh được để test nhanh).
  final Duration tick;
  final Duration startHold;

  const GetReadyScreen({
    super.key,
    required this.me,
    required this.partner,
    this.tick = const Duration(seconds: 1),
    this.startHold = const Duration(milliseconds: 800),
  });

  @override
  State<GetReadyScreen> createState() => _GetReadyScreenState();
}

class _GetReadyScreenState extends State<GetReadyScreen> with SingleTickerProviderStateMixin {
  static const _start = 3;

  // Chu kỳ 4s: sóng lan ra nền; các hiệu ứng nhanh hơn (2s) là bội của nó nên vòng lặp không bị giật.
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  int _count = _start; // 0 = đã tới "Bắt đầu!"
  Timer? _tickTimer;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(widget.tick, _onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt "giảm chuyển động": dừng hiệu ứng, số đếm ngược vẫn chạy.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _holdTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _onTick(Timer timer) {
    setState(() => _count--);
    if (_count <= 0) {
      timer.cancel();
      _holdTimer = Timer(widget.startHold, _goToQuiz);
    }
  }

  // TODO: thay bằng màn AI Quiz thật (5 câu hỏi) khi có thiết kế.
  void _goToQuiz() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => QuizPlaceholderScreen(partner: widget.partner)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(child: CustomPaint(painter: _RipplePainter(_anim))),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Không có nút back: đang đồng bộ đếm ngược với người kia.
                    const OnboardingHeader(trailing: StatusBadge(label: 'Đã kết nối', color: AppColors.cyan)),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Stage(anim: _anim, count: _count, me: widget.me, partner: widget.partner),
                              const SizedBox(height: 40),
                              const Text(
                                'Cả hai đã sẵn sàng',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFE6DEFF), fontSize: 28, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chuẩn bị bắt đầu AI Quiz',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: const Color(0xFFCDC3D5).withValues(alpha: 0.85), fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đáp án của bạn sẽ được ẩn với đối phương.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hai avatar hai bên, vòng đếm ngược ở giữa, đường năng lượng nối từng avatar vào vòng.
class _Stage extends StatelessWidget {
  final Animation<double> anim;
  final int count;
  final AppUser me;
  final AppUser partner;

  const _Stage({required this.anim, required this.count, required this.me, required this.partner});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Màn hẹp (≤ 340px) thì avatar, nhãn và vòng đếm đều nhỏ lại để vẫn đủ chỗ cho đường nối.
        final compact = constraints.maxWidth < 340;
        final avatar = compact ? 56.0 : 64.0;
        final labelWidth = compact ? 68.0 : 84.0;
        final minLine = compact ? 12.0 : 16.0;
        final circle = (constraints.maxWidth - 2 * labelWidth - 2 * minLine).clamp(100.0, 192.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Player(user: me, color: AppColors.magenta, avatar: avatar, width: labelWidth),
            Expanded(child: _EnergyLine(anim: anim, leftToRight: true)),
            _CountdownCircle(anim: anim, count: count, size: circle),
            Expanded(child: _EnergyLine(anim: anim, leftToRight: false)),
            _Player(user: partner, color: AppColors.cyan, avatar: avatar, width: labelWidth),
          ],
        );
      },
    );
  }
}

class _Player extends StatelessWidget {
  final AppUser user;
  final Color color;
  final double avatar;
  final double width;

  const _Player({required this.user, required this.color, required this.avatar, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatar,
            height: avatar,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2B2546),
              border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 25)],
            ),
            child: AvatarImage(avatarId: user.avatarId, size: avatar - 8),
          ),
          const SizedBox(height: 8),
          Text(
            user.nickname ?? 'Ẩn danh',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE6DEFF), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final Animation<double> anim;
  final int count;
  final double size;

  const _CountdownCircle({required this.anim, required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    final started = count <= 0;

    return Semantics(
      liveRegion: true,
      label: started ? 'Bắt đầu' : 'Bắt đầu sau $count giây',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, child) {
            final pulse = (anim.value * 2) % 1; // nhịp 2s: vòng sáng lan ra rồi tan
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xCC140E2E),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.85), width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 40),
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.4 * (1 - pulse)),
                    blurRadius: 4,
                    spreadRadius: 22 * pulse,
                  ),
                  BoxShadow(
                    color: AppColors.magenta.withValues(alpha: 0.25 * (1 - pulse)),
                    blurRadius: 4,
                    spreadRadius: 36 * pulse,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x993A3556), Color(0x99201B3B)],
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(animation), child: child),
              ),
              child: FittedBox(
                key: ValueKey(count),
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cyan, Color(0xFFF1AFFF)],
                  ).createShader(bounds),
                  child: Text(
                    started ? 'Bắt đầu!' : '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: started ? 36 : 96,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đường nối avatar ↔ vòng đếm: vạch gradient và vài hạt sáng chạy từ avatar vào vòng.
class _EnergyLine extends StatelessWidget {
  final Animation<double> anim;
  final bool leftToRight;

  const _EnergyLine({required this.anim, required this.leftToRight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: RepaintBoundary(child: CustomPaint(painter: _EnergyPainter(anim, leftToRight))),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  final Animation<double> anim;
  final bool leftToRight;

  _EnergyPainter(this.anim, this.leftToRight) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    // Đầu gần avatar là magenta mờ, đầu gần vòng là cyan sáng.
    final colors = leftToRight
        ? [AppColors.magenta.withValues(alpha: 0), AppColors.magenta.withValues(alpha: 0.8), AppColors.cyan.withValues(alpha: 0.9)]
        : [AppColors.cyan.withValues(alpha: 0.9), AppColors.magenta.withValues(alpha: 0.8), AppColors.magenta.withValues(alpha: 0)];
    final line = Rect.fromLTWH(0, y - 1.5, size.width, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(line)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Hạt sáng chạy hướng vào vòng đếm (chu kỳ 2s, hai hạt lệch pha)
    for (var i = 0; i < 2; i++) {
      final phase = (anim.value * 2 + i * 0.5) % 1;
      final x = size.width * (leftToRight ? phase : 1 - phase);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = AppColors.cyan.withValues(alpha: 0.8 * sin(phase * pi))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter oldDelegate) => oldDelegate.leftToRight != leftToRight;
}

/// Ba vòng sóng mờ lan ra từ giữa màn hình, lệch pha nhau.
class _RipplePainter extends CustomPainter {
  final Animation<double> anim;

  _RipplePainter(this.anim) : super(repaint: anim);

  static const _base = [150.0, 225.0, 300.0];
  static const _offset = [0.0, 0.375, 0.75];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < _base.length; i++) {
      final phase = (anim.value + _offset[i]) % 1;
      canvas.drawCircle(
        c,
        _base[i] * (0.8 + 0.7 * phase),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = (i == 1 ? AppColors.lilac : AppColors.cyan).withValues(alpha: 0.28 * (1 - phase))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => false;
}
