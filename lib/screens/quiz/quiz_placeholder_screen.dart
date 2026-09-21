import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../main/main_shell.dart';

/// Màn AI Quiz (tạm): 5 câu hỏi chiều sâu chấm rule-based sẽ làm khi có thiết kế.
class QuizPlaceholderScreen extends StatelessWidget {
  final AppUser partner;

  const QuizPlaceholderScreen({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                const OnboardingHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarImage(avatarId: partner.avatarId, size: 88),
                        const SizedBox(height: 16),
                        Text(
                          'Bạn đang kết nối với ${partner.nickname ?? 'một người ẩn danh'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'AI Quiz',
                          style: TextStyle(color: AppColors.cyan, fontSize: 32, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '5 câu hỏi chiều sâu sẽ xuất hiện ở đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Về Radar',
                          style: PrimaryButtonStyle.outline,
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(builder: (_) => const MainShell()),
                            (_) => false,
                          ),
                        ),
                      ],
                    ),
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
