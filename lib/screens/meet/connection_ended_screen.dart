import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/primary_button.dart';
import '../main/main_shell.dart';

const _reportReasons = [
  'Nội dung không phù hợp',
  'Quấy rối hoặc spam',
  'Hỏi thông tin cá nhân quá sớm',
  'Cảm thấy không an toàn khi gặp mặt',
  'Lý do khác',
];

/// Màn kết quả cuối cùng khi MỘT TRONG HAI chọn "Không tiếp tục": xác nhận kết nối đã kết thúc,
/// không lưu vào Danh bạ. Điểm dừng của luồng — mọi nút đều dẫn thẳng về MainShell.
class ConnectionEndedScreen extends StatelessWidget {
  final AppUser partner;

  const ConnectionEndedScreen({super.key, required this.partner});

  void _goToRadar(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  Future<void> _reportIssue(BuildContext context) async {
    final name = partner.nickname ?? 'người này';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Báo cáo sự cố với $name',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          for (final r in _reportReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(r),
              child: Text(
                r,
                style: const TextStyle(color: Color(0xFFE6DEFF), fontSize: 15),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF968D9F), fontSize: 15),
            ),
          ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;

    MockUserStore.blockUser(partner.id);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MainShell(
          notice: 'Đã gửi báo cáo. Người này sẽ không xuất hiện lại với bạn.',
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = partner.nickname ?? 'Ẩn danh';

    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        // Màn này ít card che nền nên các vùng glow lộ rõ hơn hẳn chỗ khác; phủ tối nhẹ cho dịu bớt.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _CloseHeader(
                  title: 'Kết nối đã kết thúc',
                  subtitle: 'Bạn đã chọn không tiếp tục',
                  onClose: () => _goToRadar(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        const _MoonOrb(),
                        const SizedBox(height: 24),
                        Text(
                          'Kết nối với $name đã kết thúc',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NearSoul tôn trọng lựa chọn của bạn. Kết nối này sẽ không được lưu vào Danh bạ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.85),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GlowCard(
                          padding: const EdgeInsets.all(14),
                          radius: 18,
                          child: Row(
                            children: [
                              AvatarImage(avatarId: partner.avatarId, size: 52),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Kết nối đã kết thúc',
                                      style: TextStyle(
                                        color: const Color(0xFFCDC3D5)
                                            .withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.do_not_disturb_on,
                                          size: 13,
                                          color: AppColors.cyan,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Không lưu vào Danh bạ',
                                          style: TextStyle(
                                            color: AppColors.cyan,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Quay lại Radar',
                          icon: Icons.explore,
                          onPressed: () => _goToRadar(context),
                        ),
                        const SizedBox(height: 12),
                        _OutlineButton(
                          label: 'Báo cáo sự cố',
                          icon: Icons.report_outlined,
                          onPressed: () => _reportIssue(context),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '"Bạn luôn có thể chặn hoặc báo cáo nếu cảm thấy không an toàn."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.45),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
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

class _CloseHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _CloseHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: onClose,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, color: Color(0xFFCDC3D5)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
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

/// Vầng sáng lớn mờ dần phía sau + vòng tròn kính chứa icon mặt trăng — êm dịu, không mang tính lỗi/cảnh báo.
class _MoonOrb extends StatefulWidget {
  const _MoonOrb();

  @override
  State<_MoonOrb> createState() => _MoonOrbState();
}

class _MoonOrbState extends State<_MoonOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
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
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: 180 + 14 * _controller.value,
              height: 180 + 14 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.2),
                    AppColors.purple.withValues(alpha: 0.06),
                    AppColors.onboardingBg.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF241850).withValues(alpha: 0.6),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.nightlight_round,
                  color: AppColors.cyan,
                  size: 34,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Đã ghi nhận lựa chọn',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        shape: StadiumBorder(
          side: BorderSide(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: const Color(0xFFCDC3D5)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFCDC3D5),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
