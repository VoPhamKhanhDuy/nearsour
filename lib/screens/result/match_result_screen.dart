import 'dart:math';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../utils/quiz_scoring.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_badge.dart';
import '../chat/chat_room_screen.dart';
import '../main/main_shell.dart';
import '../quiz/quiz_screen.dart' show kConnectionEndedMessage;

/// Báo kết quả sau Quiz khi hai người khớp. "Mở phòng chat" vào chat 48 giờ;
/// "Bỏ qua kết nối này" hủy kết quả (phòng chat không mở, không lưu gì lại).
class MatchResultScreen extends StatelessWidget {
  final Match match;
  final AppUser me;
  final AppUser partner;

  const MatchResultScreen({
    super.key,
    required this.match,
    required this.me,
    required this.partner,
  });

  void _openChat(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(match: match, partner: partner),
      ),
      (_) => false,
    );
  }

  /// Bỏ qua kết nối: hủy kết quả rồi về Radar. Không hoàn tác được nên luôn hỏi lại trước.
  Future<void> _confirmSkip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Bỏ qua kết nối này?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Phòng chat sẽ không được mở và đáp án của bạn không được lưu lại.',
          style: TextStyle(color: Color(0xFFCDC3D5), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Bỏ qua kết nối'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Phía người kia sẽ nhận thông báo trung tính qua backend (socket) khi có; mock chỉ ghi trạng thái hết hạn.
    MockUserStore.cancelMatchResult(match.id);
    me.isScanning = true; // "tiếp tục quét..."
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MainShell(notice: kConnectionEndedMessage),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = matchPercent(match.quizScore);
    final theirAnswers = match.freeTextAnswers[partner.id] ?? const <String>[];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmSkip(context);
      },
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                OnboardingHeader(
                  onBack: () => _confirmSkip(context),
                  trailing: const StatusBadge(
                    label: 'Đã kết nối',
                    color: AppColors.cyan,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      children: [
                        const Text(
                          'Kết nối thành công',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'AI đã tìm thấy điểm chung phù hợp trong câu trả lời của hai bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFCDC3D5)
                                  .withValues(alpha: 0.85),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _ResultOrb(percent: percent),
                        const SizedBox(height: 24),
                        const _ChatOpenedCard(),
                        const SizedBox(height: 16),
                        if (theirAnswers.isNotEmpty) ...[
                          _AnswersCard(
                            name: partner.nickname ?? 'Người ấy',
                            questions: match.freeTextQuestions,
                            answers: theirAnswers,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Color(0xFF968D9F),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Thông tin cá nhân vẫn được bảo vệ cho đến khi cả hai xác thực gặp mặt.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF968D9F),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Mở phòng chat',
                        icon: Icons.chat_bubble,
                        onPressed: () => _openChat(context),
                      ),
                      TextButton(
                        onPressed: () => _confirmSkip(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFCDC3D5),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text(
                          'Bỏ qua kết nối này',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Text(
                        'Cuộc trò chuyện sẽ tự động hết hạn sau 48 giờ.',
                        style: TextStyle(
                          color: Color(0xFF968D9F),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vòng tròn kính với vòng tiến trình và số phần trăm chạy từ 0 lên kết quả.
class _ResultOrb extends StatelessWidget {
  static const double _orb = 192;

  final int percent;

  const _ResultOrb({required this.percent});

  @override
  Widget build(BuildContext context) {
    // Tôn trọng "giảm chuyển động": hiện luôn kết quả cuối, không chạy từ 0.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1400);

    return Semantics(
      label: 'Mức độ phù hợp $percent phần trăm',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 256,
          height: 256,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(256),
                painter: _OrbitPainter(),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent / 100),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Container(
                  width: _orb,
                  height: _orb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x99241850),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.18),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _RingPainter(value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.cyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(value * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MỨC ĐỘ PHÙ HỢP',
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
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

/// Vòng tiến trình cyan → tím nhạt chạy theo chiều kim đồng hồ từ đỉnh.
class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 2);

    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.lilac.withValues(alpha: 0.1),
    );
    if (progress <= 0) return;

    final gradient = SweepGradient(
      colors: const [AppColors.cyan, AppColors.lilac],
      transform: const GradientRotation(-pi / 2),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -pi / 2,
      progress * 2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Hai vòng mảnh tĩnh bao quanh vòng tròn kết quả.
class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      size.width / 2 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.lilac.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      c,
      size.width / 2 - 17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.cyan.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatOpenedCard extends StatelessWidget {
  const _ChatOpenedCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.cyan, width: 4)),
        ),
        child: const GlowCard(
          padding: EdgeInsets.all(20),
          radius: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.forum_outlined, color: AppColors.cyan),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng chat 48 giờ đã được mở',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bạn có thể trò chuyện ẩn danh trước khi quyết định gặp ngoài đời.',
                      style: TextStyle(
                        color: Color(0xE6CDC3D5),
                        fontSize: 15,
                        height: 1.5,
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

/// Nguyên văn các câu trả lời tự luận của người kia (lộ ra sau khi khớp) để làm chủ đề mở lời.
class _AnswersCard extends StatelessWidget {
  final String name;
  final List<String> questions;
  final List<String> answers;

  const _AnswersCard({
    required this.name,
    required this.questions,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CÂU TRẢ LỜI CỦA ${name.toUpperCase()}',
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
          for (var i = 0; i < answers.length; i++) ...[
            const SizedBox(height: 16),
            if (i < questions.length)
              Text(
                questions[i],
                style: const TextStyle(
                  color: Color(0xFFB0A8D0),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.lilac.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '“${answers[i]}”',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
