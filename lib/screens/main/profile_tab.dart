import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glow_card.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/settings_screen.dart';
import '../welcome/welcome_screen.dart';

const _metStatuses = {
  MatchStatus.metPending,
  MatchStatus.completedSaved,
  MatchStatus.completedEnded,
};

/// Tab "Cá nhân": hồ sơ ẩn danh, thống kê nhanh và lối vào Chỉnh sửa hồ sơ / Cài đặt.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
    if (mounted) setState(() {}); // cập nhật tên thật/bio/sở thích vừa sửa
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    if (mounted) {
      setState(
        () {},
      ); // cập nhật lại trạng thái (ẩn cư, danh sách chặn) vừa đổi
    }
  }

  void _logout() {
    MockUserStore.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = MockUserStore.currentUser;
    final myId = user?.id;
    final myMatches = MockUserStore.matches.where(
      (m) => m.userA == myId || m.userB == myId,
    );
    final metCount = myMatches
        .where((m) => _metStatuses.contains(m.status))
        .length;
    final triedCount = myMatches.length;
    final savedCount = user?.friendIds.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hồ sơ của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _CircleIconButton(icon: Icons.settings, onTap: _openSettings),
            ],
          ),
          const SizedBox(height: 20),
          Center(child: _AvatarHero(avatarId: user?.avatarId)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              user?.nickname ?? 'Chưa đặt biệt danh',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Biệt danh ẩn danh',
              style: TextStyle(
                color: AppColors.lilac.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 13, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Danh tính thật đang được bảo vệ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _StatsCard(
            metCount: metCount,
            triedCount: triedCount,
            savedCount: savedCount,
          ),
          const SizedBox(height: 16),
          GlowCard(
            padding: EdgeInsets.zero,
            radius: 20,
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.edit_outlined,
                  title: 'Chỉnh sửa hồ sơ',
                  subtitle: 'Cập nhật ảnh thật, tên thật và bio cá nhân.',
                  onTap: _openEditProfile,
                  showDivider: true,
                ),
                _ActionRow(
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt',
                  subtitle:
                      'Quản lý quyền riêng tư, danh sách chặn và tài khoản.',
                  onTap: _openSettings,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PrivacyNote(),
          const SizedBox(height: 12),
          // Hành động ít dùng: text link nhạt, không cạnh tranh nổi bật với 2 dòng hành động chính ở trên.
          Center(
            child: TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE6DEFF),
                minimumSize: const Size(0, 44),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2B2546).withValues(alpha: 0.6),
      shape: CircleBorder(
        side: BorderSide(color: AppColors.lilac.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 20, color: AppColors.lilac),
        ),
      ),
    );
  }
}

/// Avatar có viền phát sáng nhẹ nhàng nhấp nháy + huy hiệu lấp lánh đè góc dưới phải.
class _AvatarHero extends StatefulWidget {
  final int? avatarId;

  const _AvatarHero({required this.avatarId});

  @override
  State<_AvatarHero> createState() => _AvatarHeroState();
}

class _AvatarHeroState extends State<_AvatarHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.lilac.withValues(
                    alpha: 0.2 + 0.15 * _controller.value,
                  ),
                  width: 2,
                ),
              ),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF241850).withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lilac.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: AvatarImage(avatarId: widget.avatarId, size: 92),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple,
                border: Border.all(color: const Color(0xFF140E2E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int metCount;
  final int triedCount;
  final int savedCount;

  const _StatsCard({
    required this.metCount,
    required this.triedCount,
    required this.savedCount,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppColors.lilac.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$metCount',
                  style: const TextStyle(
                    color: AppColors.lilac,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Lần gặp mặt ngoài đời thành công',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0x334B4453)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  icon: Icons.group,
                  value: '$triedCount',
                  label: 'Kết nối đã thử',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  icon: Icons.contact_page,
                  value: '$savedCount',
                  label: 'Đang lưu trong Danh bạ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cùng kiểu "vòng tròn + số" với chỉ số chính ở trên, chỉ nhỏ hơn — phân cấp bằng kích cỡ,
/// không phải đổi hẳn sang kiểu khác (icon + số nằm ngang) như trước.
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.lilac.withValues(alpha: 0.2)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.lilac,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: const Color(0xFFCDC3D5)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.lilac),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0x334B4453),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B4453).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock,
            size: 16,
            color: AppColors.cyan.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin thật của bạn chỉ hiển thị với những kết nối đã xác thực và được lưu vào Danh bạ.',
              style: TextStyle(
                color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
