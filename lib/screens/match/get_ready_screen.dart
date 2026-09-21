import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/status_badge.dart';
import '../../mock/mock_data.dart';
import '../quiz/quiz_screen.dart';

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

class _GetReadyScreenState extends State<GetReadyScreen>
    with TickerProviderStateMixin {
  static const _start = 3;

  // Chu kỳ 4s cho hiệu ứng trang trí (sóng nền, hạt sáng chạy, vòng sáng ở tâm); các nhịp 2s là bội của nó.
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  // Vòng tiến trình quanh số đếm: chạy đều 0 → 1 trong đúng 3 nhịp. Đây là thông tin chứ không phải trang trí
  // nên vẫn chạy khi hệ thống bật "giảm chuyển động".
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.tick * _start,
  );

  int _count = _start; // 0 = đã tới "Bắt đầu!"
  Timer? _tickTimer;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _progress.forward();
    _tickTimer = Timer.periodic(widget.tick, _onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng cài đặt "giảm chuyển động": dừng hiệu ứng trang trí, số đếm ngược vẫn chạy.
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
    _progress.dispose();
    super.dispose();
  }

  void _onTick(Timer timer) {
    setState(() => _count--);
    if (_count <= 0) {
      timer.cancel();
      _progress.value = 1; // chắc chắn vòng đã đầy khi hiện "Bắt đầu!"
      _holdTimer = Timer(widget.startHold, _goToQuiz);
    }
  }

  void _goToQuiz() {
    if (!mounted) return;
    // Cùng một match cho cả hai bên; chưa có thì tạo (ví dụ khi mở thẳng màn này).
    final match = MockUserStore.quizMatchWith(widget.partner.id);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            QuizScreen(match: match, me: widget.me, partner: widget.partner),
      ),
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
                child: RepaintBoundary(
                  child: CustomPaint(painter: _RipplePainter(_anim)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Không có nút back: đang đồng bộ đếm ngược với người kia.
                    const OnboardingHeader(
                      trailing: StatusBadge(
                        label: 'Đã kết nối',
                        color: AppColors.cyan,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Màn thấp thì thu nhỏ vòng đếm và khoảng cách để không phải cuộn.
                          final compact = constraints.maxHeight < 520;
                          return Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _Stage(
                                    anim: _anim,
                                    progress: _progress,
                                    count: _count,
                                    me: widget.me,
                                    partner: widget.partner,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 16 : 32),
                                  const _Title(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Đáp án của bạn sẽ được ẩn với đối phương.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
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

/// Tiêu đề trắng đậm (gradient chỉ dành cho vòng đếm ngược); dòng phụ nhỏ và mờ hơn hẳn.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Cả hai đã sẵn sàng',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Chuẩn bị bắt đầu AI Quiz',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Hai avatar ở trên, hai đường cong sáng chụm xuống vòng đếm ngược ở dưới ("hai người đang kết nối").
class _Stage extends StatelessWidget {
  final Animation<double> anim;
  final Animation<double> progress;
  final int count;
  final AppUser me;
  final AppUser partner;
  final bool compact;

  const _Stage({
    required this.anim,
    required this.progress,
    required this.count,
    required this.me,
    required this.partner,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = compact ? 56.0 : 72.0;
    const labelWidth = 92.0;
    final connectorHeight = compact ? 44.0 : 72.0;
    final circle = compact ? 150.0 : 200.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Player(user: me, avatar: avatar, width: labelWidth),
            _Player(user: partner, avatar: avatar, width: labelWidth),
          ],
        ),
        SizedBox(
          key: const ValueKey('connector'),
          width: double.infinity,
          height: connectorHeight,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _ConnectorPainter(anim, labelWidth / 2),
            ),
          ),
        ),
        _CountdownCircle(progress: progress, count: count, size: circle),
      ],
    );
  }
}

class _Player extends StatelessWidget {
  final AppUser user;
  final double avatar;
  final double width;

  const _Player({
    required this.user,
    required this.avatar,
    required this.width,
  });

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
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                  blurRadius: 18,
                ),
              ],
            ),
            child: AvatarImage(avatarId: user.avatarId, size: avatar - 8),
          ),
          const SizedBox(height: 8),
          Text(
            user.nickname ?? 'Ẩn danh',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE6DEFF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  static const double _ringGap =
      14; // khoảng từ viền vòng đếm tới vòng tiến trình

  final Animation<double> progress;
  final int count;
  final double size;

  const _CountdownCircle({
    required this.progress,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final started = count <= 0;
    final outer = size + 2 * _ringGap;

    return Semantics(
      liveRegion: true,
      label: started ? 'Bắt đầu' : 'Bắt đầu sau $count giây',
      child: ExcludeSemantics(
        child: SizedBox(
          width: outer,
          height: outer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vòng tiến trình chạy dần quanh viền theo thời gian (cùng một màu cyan với viền).
              CustomPaint(
                key: const ValueKey('countdown-ring'),
                size: Size.square(outer),
                painter: _RingPainter(progress),
              ),
              // Một lớp viền cyan + một lớp glow cyan.
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xCC140E2E),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.85),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 32,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: FittedBox(
                    key: ValueKey(count),
                    fit: BoxFit.scaleDown,
                    child: Text(
                      started ? 'Bắt đầu!' : '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: started ? 34 : 88,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vòng tiến trình mỏng: nền mờ + cung cyan chạy theo chiều kim đồng hồ từ đỉnh (một màu, một lớp glow cyan).
class _RingPainter extends CustomPainter {
  final Animation<double> progress;

  _RingPainter(this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2 + 1);
    final sweep = progress.value.clamp(0.0, 1.0) * 2 * pi;

    canvas.drawArc(
      arcRect,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    if (sweep <= 0) return;

    canvas.drawArc(
      arcRect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cyan.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawArc(
      arcRect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cyan,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

/// Hai đường cong mảnh một màu cyan từ tâm mỗi avatar chụm xuống đỉnh vòng đếm, kèm hạt sáng nhỏ chạy xuống.
class _ConnectorPainter extends CustomPainter {
  final Animation<double> anim;
  final double sideInset; // khoảng từ mép tới tâm avatar

  _ConnectorPainter(this.anim, this.sideInset) : super(repaint: anim);

  static Path _curve(double fromX, double toX, double h) => Path()
    ..moveTo(fromX, 0)
    ..cubicTo(fromX, h * 0.65, toX, h * 0.35, toX, h);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paths = [
      _curve(sideInset, w / 2, h),
      _curve(w - sideInset, w / 2, h),
    ];

    // Mờ ở đầu avatar, rõ dần khi chụm vào vòng đếm.
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.cyan.withValues(alpha: 0.25),
        AppColors.cyan.withValues(alpha: 0.6),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (final path in paths) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..shader = shader,
      );

      // Hạt sáng chạy từ avatar xuống vòng đếm (chu kỳ 2s, hai hạt lệch pha)
      final metric = path.computeMetrics().first;
      for (var i = 0; i < 2; i++) {
        final phase = (anim.value * 2 + i * 0.5) % 1;
        final tangent = metric.getTangentForOffset(metric.length * phase);
        if (tangent == null) continue;
        canvas.drawCircle(
          tangent.position,
          2.5,
          Paint()
            ..color = AppColors.cyan.withValues(alpha: 0.75 * sin(phase * pi)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.sideInset != sideInset;
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
          ..color = AppColors.cyan.withValues(alpha: 0.22 * (1 - phase))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => false;
}
