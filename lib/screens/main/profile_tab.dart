import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import '../welcome/welcome_screen.dart';

/// Tab "Cá nhân" (tạm): hồ sơ ẩn danh và đăng xuất. Cài đặt, chế độ ẩn cư, danh sách chặn sẽ làm sau.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  static String _genderLabel(String? gender) => switch (gender) {
        'male' => 'Nam',
        'female' => 'Nữ',
        'other' => 'Khác',
        _ => '—',
      };

  @override
  Widget build(BuildContext context) {
    final user = MockUserStore.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          AvatarImage(avatarId: user?.avatarId, size: 96),
          const SizedBox(height: 16),
          Text(
            user?.nickname == null ? 'Chưa đặt biệt danh' : 'Xin chào, ${user!.nickname}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
          const SizedBox(height: 24),
          GlowCard(
            child: Column(
              children: [
                _InfoRow(label: 'Năm sinh', value: user?.birthYear?.toString() ?? '—'),
                const Divider(height: 24, color: Color(0x1AFFFFFF)),
                _InfoRow(label: 'Giới tính', value: _genderLabel(user?.gender)),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFB0A8D0), fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
