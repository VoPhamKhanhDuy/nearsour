import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/radar_view.dart';
import '../../widgets/step_progress.dart';
import 'radar_permission_screen.dart';
import 'intro_48h_screen.dart';

/// Bước 2/3 của phần tạo hồ sơ: giới thiệu tính năng phát hiện người trong bán kính 200m.
class GpsIntroScreen extends StatelessWidget {
  const GpsIntroScreen({super.key});

  // "Bỏ qua" bỏ luôn phần giới thiệu còn lại và sang trang kích hoạt Radar.
  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RadarPermissionScreen()),
      (_) => false,
    );
  }

  void _next(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Intro48hScreen()));
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
                onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
                actionLabel: 'Bỏ qua',
                onAction: () => _skip(context),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: StepProgress(step: 2, total: 3),
              ),
              // Radar chiếm phần chiều cao còn lại và tự co nhỏ trên màn hình thấp.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: const RadarView(),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: _Intro(),
              ),
              const SizedBox(height: 16),
              const _FeaturePills(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PrimaryButton(label: 'Tiếp theo →', onPressed: () => _next(context)),
              ),
              const SizedBox(height: 10),
              Text(
                'Bạn có thể bỏ qua phần này',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE0CFFF)],
          ).createShader(bounds),
          child: const Text(
            'Kết nối với người gần bạn',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'NearSoul phát hiện những người đang ở trong bán kính 200m — cùng không gian, cùng thời điểm, hoàn toàn ẩn danh.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFC8C0E8), fontSize: 13.5, height: 1.5),
        ),
      ],
    );
  }
}

class _FeaturePills extends StatelessWidget {
  const _FeaturePills();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _FeaturePill(icon: Icons.location_on, label: 'GPS 200m'),
        _FeaturePill(icon: Icons.visibility_off, label: 'Ẩn danh'),
        _FeaturePill(icon: Icons.bolt, label: 'Real-time'),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC2A1870),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.magenta.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.cyan),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
