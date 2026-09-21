import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/step_progress.dart';
import 'radar_permission_screen.dart';

/// Bước 3/3 (cuối) của phần tạo hồ sơ: giới thiệu cửa sổ kết nối ẩn danh 48 giờ (Quiz → Chat → Gặp nhau).
class Intro48hScreen extends StatelessWidget {
  static const _subtle = Color(0xFF9A8CC8);

  const Intro48hScreen({super.key});

  // Xong 3 bước tạo hồ sơ: sang trang kích hoạt Radar và bỏ các màn thiết lập khỏi stack.
  void _finish(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RadarPermissionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              OnboardingHeader(
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: Column(
                          children: [
                            const StepProgress(step: 3, total: 3),
                            const SizedBox(height: 20),
                            const _WindowCard(),
                            const SizedBox(height: 24),
                            const _Intro(),
                            const SizedBox(height: 20),
                            const _StatsRow(),
                            const Spacer(),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: 'Bắt đầu ngay →',
                              onPressed: () => _finish(context),
                            ),
                          ],
                        ),
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

/// Card chủ đạo: số 48 thật to, bên dưới là 3 bước Quiz → Chat → Gặp nhau.
class _WindowCard extends StatelessWidget {
  const _WindowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.magenta.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.magenta.withValues(alpha: 0.25),
            blurRadius: 32,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '48',
            style: TextStyle(
              color: AppColors.magenta,
              fontSize: 76,
              height: 1,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: AppColors.magenta.withValues(alpha: 0.8),
                  blurRadius: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'GIỜ',
            style: TextStyle(
              color: AppColors.magenta.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cửa sổ kết nối ẩn danh',
            style: TextStyle(color: Intro48hScreen._subtle, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Step(
                    icon: Icons.psychology_alt_outlined,
                    title: 'AI Quiz',
                    caption: 'Tìm người hợp tính',
                  ),
                ),
                _StepDivider(),
                Expanded(
                  child: _Step(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    caption: 'Ẩn danh 48 giờ',
                  ),
                ),
                _StepDivider(),
                Expanded(
                  child: _Step(
                    icon: Icons.handshake_outlined,
                    title: 'Gặp nhau',
                    caption: 'Hẹn gặp ngoài đời',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title;
  final String caption;

  const _Step({required this.icon, required this.title, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.magenta.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.magenta.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 20, color: AppColors.cyan),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Intro48hScreen._subtle,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kết nối sâu sắc trong 48 giờ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: AppColors.magenta.withValues(alpha: 0.6),
                blurRadius: 28,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320),
          child: Text(
            'Trả lời câu hỏi AI để tìm người hợp tư duy — chat ẩn danh 48 giờ trước khi gặp nhau ngoài đời.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC8C0E8),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hai con số mới so với card phía trên (không nhắc lại 48h): số câu hỏi và điều kiện mở chat.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '5',
            label: 'Câu hỏi AI',
            color: AppColors.magenta,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '3/5',
            label: 'Câu trùng để mở chat',
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB0A8D0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
