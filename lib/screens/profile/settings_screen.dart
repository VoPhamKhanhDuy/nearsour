import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../welcome/welcome_screen.dart';
import 'blocked_users_screen.dart';
import 'edit_profile_screen.dart';

/// Cài đặt: quyền riêng tư, an toàn và tài khoản. "Chế độ ẩn cư" và "Danh sách chặn" là chức năng thật
/// (đọc/ghi trực tiếp AppUser); "Báo cáo sự cố" và "Xóa tài khoản" mới chỉ là lối vào, xử lý thật cần backend.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _openBlockedList() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BlockedUsersScreen()));
    if (mounted) setState(() {});
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Gửi phản hồi cho đội ngũ NearSoul sẽ có ở bản sau.'),
        ),
      );
  }

  void _logout() {
    MockUserStore.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Xóa tài khoản vĩnh viễn?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Hồ sơ, Danh bạ và lịch sử kết nối sẽ mất hết, không thể hoàn tác.',
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
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Mock: chưa thật sự xoá dữ liệu tài khoản (cần backend) — chỉ đăng xuất.
    _logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = MockUserStore.currentUser;

    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlowCard(
                        padding: const EdgeInsets.all(14),
                        radius: 20,
                        child: Row(
                          children: [
                            AvatarImage(avatarId: user?.avatarId, size: 48),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.nickname ?? 'Chưa đặt biệt danh',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Biệt danh ẩn danh',
                                    style: TextStyle(
                                      color: const Color(0xFFCDC3D5)
                                          .withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (user?.isOnline ?? false)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.cyan.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Đang hoạt động',
                                  style: TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('QUYỀN RIÊNG TƯ'),
                      const SizedBox(height: 10),
                      GlowCard(
                        padding: EdgeInsets.zero,
                        radius: 20,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.visibility_off_outlined,
                              title: 'Chế độ ẩn cư',
                              subtitle: 'Ẩn bạn khỏi người lạ trên Radar.',
                              trailing: Switch(
                                value: user?.isHidden ?? false,
                                activeThumbColor: AppColors.cyan,
                                onChanged: (v) {
                                  setState(() => user?.isHidden = v);
                                },
                              ),
                              showDivider: true,
                            ),
                            _SettingsRow(
                              icon: Icons.lock_outline,
                              title: 'Thông tin thật',
                              subtitle:
                                  'Chỉ kết nối đã xác thực mới có thể xem.',
                              trailing: const _ChevronIcon(),
                              onTap: _openEditProfile,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('AN TOÀN'),
                      const SizedBox(height: 10),
                      GlowCard(
                        padding: EdgeInsets.zero,
                        radius: 20,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.block_outlined,
                              title: 'Danh sách chặn',
                              subtitle: 'Quản lý tài khoản đã chặn.',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if ((user?.blockedUsers.length ?? 0) > 0) ...[
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error,
                                      ),
                                      child: Text(
                                        '${user!.blockedUsers.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const _ChevronIcon(),
                                ],
                              ),
                              onTap: _openBlockedList,
                              showDivider: true,
                            ),
                            _SettingsRow(
                              icon: Icons.outlined_flag,
                              title: 'Báo cáo sự cố',
                              subtitle:
                                  'Gửi phản hồi về hành vi không an toàn.',
                              trailing: const _ChevronIcon(),
                              onTap: _reportIssue,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('TÀI KHOẢN'),
                      const SizedBox(height: 10),
                      GlowCard(
                        padding: EdgeInsets.zero,
                        radius: 20,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.logout,
                              title: 'Đăng xuất',
                              subtitle: 'Thoát khỏi phiên đăng nhập hiện tại.',
                              trailing: const _ChevronIcon(),
                              onTap: _logout,
                              showDivider: true,
                            ),
                            _SettingsRow(
                              icon: Icons.delete_outline,
                              title: 'Xóa tài khoản vĩnh viễn',
                              subtitle: 'Xóa tài khoản và dữ liệu liên quan.',
                              onTap: _deleteAccount,
                              danger: true,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Bạn có thể thay đổi thiết lập quyền riêng tư bất cứ lúc nào.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.5),
                            fontSize: 11.5,
                          ),
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
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE6DEFF)),
          ),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cài đặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Quyền riêng tư & tài khoản',
                  style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.lilac.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ChevronIcon extends StatelessWidget {
  const _ChevronIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      color: const Color(0xFFCDC3D5).withValues(alpha: 0.4),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool danger;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.showDivider,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = danger ? AppColors.error : Colors.white;
    final iconColor = danger ? AppColors.error : AppColors.lilac;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (danger ? AppColors.error : Colors.white).withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
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
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0x334B4453),
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }
}
