import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../widgets/avatar_image.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nearsoul_logo.dart';
import '../../widgets/primary_button.dart';
import '../welcome/welcome_screen.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockUserStore.currentUser;

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const NearSoulLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Đăng nhập thành công',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (user?.nickname != null) ...[
                  AvatarImage(avatarId: user!.avatarId, size: 72),
                  const SizedBox(height: 12),
                ],
                Text(
                  user?.nickname == null ? '' : 'Xin chào, ${user!.nickname}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 40),
                PrimaryButton(
                  label: 'Đăng xuất',
                  style: PrimaryButtonStyle.outline,
                  onPressed: () {
                    MockUserStore.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
