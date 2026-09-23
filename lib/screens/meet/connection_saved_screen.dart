import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import '../main/main_shell.dart';

/// Màn kết quả cuối cùng khi CẢ HAI cùng chọn "Giữ kết nối": xác nhận đã lưu vào Danh bạ.
/// Đây là điểm dừng của luồng — mọi nút đều dẫn thẳng về MainShell (không quay lại được màn quyết định
/// trước đó vì quyết định đã chốt xong rồi).
class ConnectionSavedScreen extends StatelessWidget {
  final AppUser partner;

  const ConnectionSavedScreen({super.key, required this.partner});

  void _goToShell(BuildContext context, {int tab = 0}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => MainShell(initialTab: tab)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = partner.nickname ?? 'Người ấy';

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
                  title: 'Kết nối thành công',
                  subtitle: 'Đã lưu vào Danh bạ',
                  onClose: () => _goToShell(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        const _PulseOrb(
                          icon: Icons.favorite,
                          label: 'Đã lưu kết nối',
                          color: AppColors.cyan,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          '$name đã được thêm vào Danh bạ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _ConnectionCard(
                          partner: partner,
                          statusLabel: 'Đã xác thực',
                          statusColor: AppColors.cyan,
                          trailing: 'Đã gặp ngoài đời',
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Bạn muốn làm gì tiếp theo?',
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: 'Xem Danh bạ',
                          icon: Icons.people_alt,
                          onPressed: () => _goToShell(context, tab: 1),
                        ),
                        const SizedBox(height: 12),
                        _OutlineButton(
                          label: 'Quay lại Radar',
                          icon: Icons.explore,
                          onPressed: () => _goToShell(context),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bạn luôn có thể chặn hoặc báo cáo nếu cảm thấy không an toàn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.5),
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

/// Header dùng chung với [ConnectionEndedScreen]: nút X trái, tiêu đề 2 dòng giữa, khoảng trống phải để cân.
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

/// Vòng tròn kính có glow + hiệu ứng lan sóng (ping) phía sau, dùng cho cả 2 màn kết quả.
class _PulseOrb extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PulseOrb({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_PulseOrb> createState() => _PulseOrbState();
}

class _PulseOrbState extends State<_PulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
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
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Container(
                width: 112 + 28 * t,
                height: 112 + 28 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.15 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF241850).withValues(alpha: 0.6),
              border: Border.all(color: widget.color.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 36),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _ConnectionCard extends StatelessWidget {
  final AppUser partner;
  final String statusLabel;
  final Color statusColor;
  final String? trailing;

  const _ConnectionCard({
    required this.partner,
    required this.statusLabel,
    required this.statusColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarImage(avatarId: partner.avatarId, size: 52),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    border: Border.all(
                      color: const Color(0xFF140E2E),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.nickname ?? 'Ẩn danh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lilac.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.lilac.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: AppColors.lilac,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
